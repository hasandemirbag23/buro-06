"""Büro 06 · Tripo MCP sunucusu.

Claude Code'a Tripo'nun resmi Python SDK'sı (tripo3d) üzerinden 3B üretim araçları verir.
Blender gerekmez; sonuçlar doğrudan godot/assets/generated/<ad>/ altına iner.

Üretim dakikalar sürdüğü için araçlar iki adımlı: `*_model` görevi başlatıp task_id döner,
`tripo_task` durumu sorar ve görev bittiyse dosyaları indirir.

API anahtarı ASLA bu dosyada, .mcp.json'da ya da repoda tutulmaz. Sırayla şuradan okunur:
  1. TRIPO_API_KEY ortam değişkeni
  2. macOS Anahtar Zinciri: servis "tripo-api", hesap "buro06"
     (eklemek için: security add-generic-password -s tripo-api -a buro06 -w)
"""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

# Coğrafi konum sezgisi içe aktarmada ağa çıkıyor; MCP açılışını geciktirmesin.
os.environ.setdefault("TRIPO_DISABLE_GEO_DETECTION", "1")

from mcp.server.mcpserver import MCPServer  # noqa: E402
from tripo3d import TaskStatus, TripoClient, TripoError  # noqa: E402

GODOT = Path(__file__).resolve().parents[2]
OUT_ROOT = GODOT / "assets" / "generated"
KEYCHAIN_SERVICE = "tripo-api"
KEYCHAIN_ACCOUNT = "buro06"

server = MCPServer(
    name="tripo",
    instructions=(
        "Tripo 3D üretimi. Görev başlatan araçlar task_id döner; sonucu almak için "
        "tripo_task'ı aralıklarla çağır. Kredi harcayan araçları kullanıcının açık isteği "
        "olmadan çağırma; önce tripo_balance ile bakiyeyi göster."
    ),
)


def _api_key() -> str:
    key = os.environ.get("TRIPO_API_KEY", "").strip()
    if key:
        return key
    try:
        out = subprocess.run(
            ["security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-a", KEYCHAIN_ACCOUNT, "-w"],
            capture_output=True, text=True, timeout=10, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return out.stdout.strip() if out.returncode == 0 else ""


def _client() -> TripoClient:
    key = _api_key()
    if not key:
        raise RuntimeError(
            "Tripo API anahtarı bulunamadı. Terminalde şunu çalıştırıp anahtarı yapıştır "
            f"(ekrana yazılmaz): security add-generic-password -s {KEYCHAIN_SERVICE} -a {KEYCHAIN_ACCOUNT} -w"
        )
    return TripoClient(api_key=key)


def _safe_name(name: str) -> str:
    """Klasör adı: yalnız harf/rakam/_-; yol dışına çıkamaz. Türkçe harfler çevrilir."""
    name = name.strip().translate(str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosuCGIOSU")).lower()
    cleaned = re.sub(r"[^a-z0-9_-]+", "_", name).strip("_")
    return cleaned[:60] or "model"


async def _call(coro_fn):
    client = _client()
    try:
        return await coro_fn(client)
    except TripoError as err:
        # Hata metni anahtarı içermez; SDK yalnız API cevabını iletir.
        raise RuntimeError(f"Tripo hatası: {err}") from None
    finally:
        await client.close()


@server.tool()
async def tripo_balance() -> dict:
    """Tripo hesabının kredi bakiyesi. Kredi harcamaz; bağlantıyı denemek için de kullanılır."""
    bal = await _call(lambda c: c.get_balance())
    return {"balance": bal.balance, "frozen": bal.frozen}


@server.tool()
async def tripo_text_to_model(prompt: str, negative_prompt: str = "", face_limit: int = 0,
                              low_poly: bool = False) -> dict:
    """Metinden 3B model görevi başlatır (KREDİ HARCAR). task_id döner; sonucu tripo_task ile al.

    face_limit: 0 = Tripo varsayılanı. Oyun içi sahne eşyası için 8000-20000 makul.
    low_poly: Tripo'nun akıllı düşük poligon çıktısı.
    """
    kwargs = {}
    if negative_prompt:
        kwargs["negative_prompt"] = negative_prompt
    if face_limit > 0:
        kwargs["face_limit"] = face_limit
    if low_poly:
        kwargs["smart_low_poly"] = True
    task_id = await _call(lambda c: c.text_to_model(prompt=prompt, **kwargs))
    return {"task_id": task_id, "next": "tripo_task(task_id, name) ile durumu sor"}


@server.tool()
async def tripo_image_to_model(image_path: str, face_limit: int = 0) -> dict:
    """Yerel bir görselden 3B model görevi başlatır (KREDİ HARCAR). task_id döner.

    image_path: makinedeki PNG/JPG/WEBP dosyasının yolu.
    """
    path = Path(image_path).expanduser().resolve()
    if not path.is_file():
        raise RuntimeError(f"Görsel bulunamadı: {path}")
    kwargs = {"face_limit": face_limit} if face_limit > 0 else {}
    task_id = await _call(lambda c: c.image_to_model(image=str(path), **kwargs))
    return {"task_id": task_id, "next": "tripo_task(task_id, name) ile durumu sor"}


@server.tool()
async def tripo_rig(model_task_id: str) -> dict:
    """Biten bir model görevini insansı iskeletle rigler (KREDİ HARCAR). task_id döner."""
    task_id = await _call(lambda c: c.rig(model_task_id, rig_type="biped", out_format="glb"))
    return {"task_id": task_id, "next": "tripo_task(task_id, name) ile durumu sor"}


@server.tool()
async def tripo_task(task_id: str, name: str = "") -> dict:
    """Görevin durumunu döner. Görev başarıyla bittiyse ve name verildiyse çıktıları
    godot/assets/generated/<name>/ altına indirir. Kredi harcamaz."""

    async def run(c: TripoClient) -> dict:
        task = await c.get_task(task_id)
        info = {"task_id": task_id, "status": task.status.value, "progress": task.progress}
        if task.status != TaskStatus.SUCCESS or not name:
            return info
        out_dir = OUT_ROOT / _safe_name(name)
        out_dir.mkdir(parents=True, exist_ok=True)
        files = await c.download_task_models(task, str(out_dir))
        info["files"] = {k: str(Path(v).relative_to(GODOT)) for k, v in files.items() if v}
        info["godot_path"] = "res://" + str(out_dir.relative_to(GODOT))
        return info

    return await _call(run)


if __name__ == "__main__":
    server.run()
