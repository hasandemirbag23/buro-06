import type {
  CharacterModelConfig,
  ChatMessage,
  ClueDef,
  EsorguRecord,
  PhoneItem,
  SceneHotspot,
  SuspectDef,
  SuspectId,
} from '../engine/types';

export const ARREST_CLUE_IDS = [
  'clue_zafer_sms',
  'clue_company_record',
  'clue_pts_06kzy44',
] as const;

export const CHARACTERS: {
  player: CharacterModelConfig;
  cevdet: CharacterModelConfig;
  akbaba: CharacterModelConfig;
} = {
  player: {
    id: 'char_player',
    name: 'Komiser',
    role: 'Cinayet Büro',
    modelType: 'POLICE',
    primaryColor: '#1c1c1c',
    secondaryColor: '#4a4038',
    accessory: 'BADGE',
    currentAnimState: 'IDLE',
    heartRateBpm: 78,
  },
  cevdet: {
    id: 'char_cevdet',
    name: 'Başkomiser Cevdet',
    role: 'Amir',
    modelType: 'POLICE',
    primaryColor: '#6e2430',
    secondaryColor: '#2a2420',
    accessory: 'TEA_GLASS',
    currentAnimState: 'IDLE',
    heartRateBpm: 84,
  },
  akbaba: {
    id: 'char_akbaba',
    name: 'Akbaba',
    role: 'Olay Yeri',
    modelType: 'FORENSIC',
    primaryColor: '#c4552a',
    secondaryColor: '#242424',
    accessory: 'CAMERA',
    currentAnimState: 'IDLE',
    heartRateBpm: 76,
  },
};

const zafer: CharacterModelConfig = {
  id: 'char_zafer',
  name: 'Zafer',
  role: 'Şantiye Şefi',
  modelType: 'SITE_CHIEF',
  primaryColor: '#e0b000',
  secondaryColor: '#3d4a22',
  accessory: 'HARD_HAT',
  currentAnimState: 'IDLE',
  heartRateBpm: 75,
};

const tarik: CharacterModelConfig = {
  id: 'char_tarik',
  name: 'Tarık Soylu',
  role: 'Müteahhit',
  modelType: 'CRIMINAL_BOSS',
  primaryColor: '#1a2744',
  secondaryColor: '#c6a15b',
  accessory: 'GOLD_WATCH',
  currentAnimState: 'ARROGANT',
  heartRateBpm: 75,
};

const hotspots: SceneHotspot[] = [
  {
    id: 'hotspot_phone',
    title: 'Ceset ve telefon',
    subtitle: 'Kırık ekran, delil poşeti',
    position: { x: 28, y: 62 },
    icon: '📱',
    unlocksClueId: 'clue_victim_phone',
    inspectorDialogue: {
      speaker: 'Akbaba',
      text: 'Ekran kırık, kasa sağlam. Poşete koy. Şifresi şantiye ofisinde bir yerde duruyordur.',
    },
  },
  {
    id: 'hotspot_desk',
    title: 'Şantiye masası',
    subtitle: 'Kupa ve takvim',
    position: { x: 74, y: 30 },
    icon: '🏆',
    unlocksClueId: 'clue_desk_photo',
    inspectorDialogue: {
      speaker: 'Komiser',
      text: 'Beşiktaş kupası. Takvimde kırmızı kalemle 19.03. Bunu şifre diye kenara yaz.',
    },
  },
  {
    id: 'hotspot_column',
    title: 'Çatlak kolon',
    subtitle: 'Eksik demir, taze çatlak',
    position: { x: 18, y: 34 },
    icon: '🧱',
    unlocksClueId: 'clue_cracked_column',
    inspectorDialogue: {
      speaker: 'Akbaba',
      text: 'Bu kolon C35 gibi durmuyor. Demir eksik, çatlak taze. Numuneyi aldım.',
    },
  },
  {
    id: 'hotspot_suv',
    title: 'SUV lastik izi',
    subtitle: 'Çamur ve kule kamerası',
    position: { x: 68, y: 58 },
    icon: '🚙',
    unlocksClueId: 'clue_suv_photo',
    inspectorDialogue: {
      speaker: 'Başkomiser Cevdet',
      text: 'Kalın lastik, siyah SUV. Kamerada plaka 06 KZY 44. Bunu E-Sorgu’ya sok.',
    },
  },
];

const clues: ClueDef[] = [
  {
    id: 'clue_victim_phone',
    title: 'Delil #01 Maktulün Telefonu',
    summary: 'Cesedin yanındaki kırık ekranlı telefon delil poşetine girdi. Tablet uygulaması açıldı.',
    source: 'scene',
    icon: '📱',
  },
  {
    id: 'clue_desk_photo',
    title: 'Masa fotoğrafı',
    summary: 'Şantiye ofisinde Beşiktaş kupası ve takvimde 19.03 işareti.',
    source: 'scene',
    icon: '🏆',
  },
  {
    id: 'clue_cracked_column',
    title: 'Çatlak kolon',
    summary: 'Demiri eksik, çatlağı taze beton kolon. Akbaba numune aldı.',
    source: 'scene',
    icon: '🧱',
  },
  {
    id: 'clue_suv_photo',
    title: 'SUV kaydı',
    summary: 'Çamurdaki lastik izi ve kamera: siyah SUV, plaka 06 KZY 44.',
    source: 'scene',
    icon: '🚙',
  },
  {
    id: 'clue_bank_500k',
    title: '500.000 TL dekont',
    summary: 'Kuzey Hafriyat, maktule cinayetten bir gün önce 500.000 TL göndermiş. Açıklama: danışmanlık.',
    source: 'phone',
    icon: '🏦',
  },
  {
    id: 'clue_concrete_report',
    title: 'Gizli lab notu',
    summary: 'Notlar: dökülen beton C35 değil, C16. Rapor şantiye şefinden saklanmış.',
    source: 'phone',
    icon: '📝',
  },
  {
    id: 'clue_zafer_sms',
    title: 'Zafer SMS',
    summary: 'Şantiye şefi Zafer, maktulü cinayet gecesi 01:00’de 14. kata çağırmış.',
    source: 'phone',
    icon: '💬',
  },
  {
    id: 'clue_no_suicide',
    title: 'Konser mesajı',
    summary: 'Kız arkadaşıyla ertesi akşam konser planı var. İntihar tutanağı tutmuyor.',
    source: 'phone',
    icon: '🎵',
  },
  {
    id: 'clue_company_record',
    title: 'Şirket kaydı',
    summary: 'Kuzey Hafriyat Ltd. Şti. yetkilisi Tarık Soylu. Vadi Kule alt yüklenicisi.',
    source: 'esorgu',
    icon: '🏢',
  },
  {
    id: 'clue_pts_06kzy44',
    title: 'PTS 06 KZY 44',
    summary: 'Siyah SUV Tarık Soylu adına. Cinayet gecesi 01:12’de şantiyeye girmiş, 01:47’de çıkmış.',
    source: 'esorgu',
    icon: '📷',
  },
  {
    id: 'clue_hts_tarik',
    title: 'HTS Tarık Soylu',
    summary: 'Hattı 01:05–01:41 arası Vadi Kule baz istasyonunda. Ev adresi sinyal dışı.',
    source: 'esorgu',
    icon: '📡',
  },
];

const chat: ChatMessage[] = [
  {
    id: 'cevdet-1',
    sender: 'Cevdet',
    at: '00:40',
    text: 'Vadi Kule. Mühendis gece düşmüş. İntihar tutanağına inanmıyorum. Şantiyeyi sen gör.',
  },
  {
    id: 'akbaba-1',
    sender: 'Akbaba',
    at: '01:20',
    requiresClueId: 'clue_cracked_column',
    text: 'Kolon numunesi bende. Bu beton döküm günü çatlamaz. Karışım çürük.',
  },
  {
    id: 'hayalet-1',
    sender: 'Hayalet',
    at: '01:28',
    requiresClueId: 'clue_suv_photo',
    text: 'Plaka 06 KZY 44. E-Sorgu’da PTS’ye yaz. Kule kamerası geceyi tutmuş.',
  },
  {
    id: 'hayalet-2',
    sender: 'Hayalet',
    at: '01:36',
    requiresClueId: 'clue_bank_500k',
    text: 'Dekont Kuzey Hafriyat. Şirketi GBT’den geçir, yetkili kim bak.',
  },
  {
    id: 'cevdet-2',
    sender: 'Cevdet',
    at: '01:44',
    requiresClueId: 'clue_zafer_sms',
    text: 'Zafer 01:00’de yukarı çağırmış. Şefi sorguya al, la bebe.',
  },
  {
    id: 'cevdet-3',
    sender: 'Cevdet',
    at: '01:55',
    requiresClueId: 'clue_hts_tarik',
    text: 'Tarık’ın hattı şantiyede. İkisi de odada. Dosyayı kapat.',
  },
];

const esorgu: EsorguRecord[] = [
  {
    keys: ['kuzeyhafriyat', 'kuzey'],
    title: 'GBT — Kuzey Hafriyat',
    body: 'Unvan: Kuzey Hafriyat Ltd. Şti.\nYetkili: Tarık Soylu\nFaaliyet: hafriyat, beton döküm\nNot: Vadi Kule alt yüklenicisi.',
    unlocksClueId: 'clue_company_record',
  },
  {
    keys: ['06kzy44'],
    title: 'PTS — 06 KZY 44',
    body: 'Araç: siyah SUV\nTescil: Tarık Soylu\nVadi Kule kamerası: cinayet gecesi 01:12 giriş, 01:47 çıkış.',
    unlocksClueId: 'clue_pts_06kzy44',
  },
  {
    keys: ['tariksoylu', 'tarik'],
    title: 'HTS — Tarık Soylu',
    body: 'Hat sinyali cinayet saatinde Vadi Kule baz istasyonunda.\n01:05 – 01:41 arası şantiye hücresi.\nEv adresi sinyal dışı.',
    unlocksClueId: 'clue_hts_tarik',
  },
];

const phoneItems: PhoneItem[] = [
  {
    id: 'bank',
    app: 'bank',
    title: 'CepBank',
    body: 'Gönderen: Kuzey Hafriyat Ltd. Şti.\nAlıcı: maktul\nTutar: 500.000 TL\nAçıklama: DANIŞMANLIK\nTarih: cinayetten bir gün önce',
    unlocksClueId: 'clue_bank_500k',
  },
  {
    id: 'notes',
    app: 'notes',
    title: 'Notlar',
    body: 'Lab notu, gizli:\nDökülen beton C35 değil, C16.\nKolon numunesi standart dışı.\nBu raporu şantiye şefi görmesin.',
    unlocksClueId: 'clue_concrete_report',
  },
  {
    id: 'sms_zafer',
    app: 'sms',
    title: 'SMS — Zafer',
    body: 'Zafer: Gece 01:00. 14. kata tek başına çık. Kalıbı birlikte göreceğiz. Kimseye söyleme.',
    unlocksClueId: 'clue_zafer_sms',
  },
  {
    id: 'sms_concert',
    app: 'sms',
    title: 'SMS — Deniz',
    body: 'Deniz: Yarın akşam konser, biletler bende. Geç kalma.\nMaktul: Çıkarım. Bu gece son kez şantiyeye uğrayacağım.',
    unlocksClueId: 'clue_no_suicide',
  },
];

const suspects: SuspectDef[] = [
  {
    id: 'zafer',
    character: zafer,
    acceptedClueIds: ['clue_zafer_sms', 'clue_concrete_report', 'clue_cracked_column'],
    lines: {
      idle: 'Ben sadece şefim komiserim. O gece evdeydim, çay içiyordum.',
      hit: 'Tamam… terledim, görüyorsun. Devam etme.',
      miss: 'Bu kâğıt beni bağlamaz. Baretim masada duruyor, ben değil.',
      confess: '01:00’de çağırdım. Tarık söyledi. C16’yı ben örttüm. Yeter.',
    },
  },
  {
    id: 'tarik',
    character: tarik,
    acceptedClueIds: [
      'clue_bank_500k',
      'clue_pts_06kzy44',
      'clue_hts_tarik',
      'clue_company_record',
    ],
    lines: {
      idle: 'Avukatım yolda. Bu tiyatro boşa, komiser.',
      hit: 'O kâğıdı masaya vurman bir şeyi değiştirmez. Henüz.',
      miss: 'Gülünç. Çayını iç. Benimle uğraşacak dosyan yok.',
      confess: '500 bin susturma parasıydı. Şantiyedeydim. Yeter, kelepçeyi tak.',
    },
  },
];

export const EPISODE = {
  pin: '1903',
  briefing:
    'La bebe, Vadi Kule şantiyesi. Mühendis gece 14. kattan düşmüş. İntihar diye yazmışlar. Akbaba ikna olmadı. Git, yerinde gör. Telefonu, kolonu, lastiği boş geçme.',
  hotspots,
  clues,
  chat,
  esorgu,
  phoneItems,
  suspects,
};

export function normalizeQuery(raw: string): string {
  return raw
    .trim()
    .toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i')
    .replace(/ş/g, 's')
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c')
    .replace(/[^a-z0-9]/g, '');
}

export function clueById(id: string): ClueDef | undefined {
  return EPISODE.clues.find((clue) => clue.id === id);
}

export function suspectById(id: SuspectId): SuspectDef {
  const found = EPISODE.suspects.find((suspect) => suspect.id === id);
  if (!found) {
    throw new Error(`Şüpheli yok: ${id}`);
  }
  return found;
}

export function arrestUnlocked(ids: readonly string[]): boolean {
  return ARREST_CLUE_IDS.some((id) => ids.includes(id));
}

export function phoneReady(ids: readonly string[]): boolean {
  return ids.includes('clue_victim_phone');
}
