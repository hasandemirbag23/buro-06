import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { DialogueBar } from '../components/shared/DialogueBar';
import type { SceneId } from '../engine/types';
import { useGameStore } from '../engine/useGameStore';
import { arrestUnlocked, CHARACTERS } from '../scenarios/episode_01';
import { colors, fontDisplay } from '../theme/colors';
import { CharacterAvatarRig } from './CharacterAvatarRig';

export function OfficeSceneView() {
  const brief = useGameStore((state) => state.brief);
  const travel = useGameStore((state) => state.travel);
  const openTablet = useGameStore((state) => state.openTablet);
  const dialogue = useGameStore((state) => state.dialogue);
  const cevdetAnim = useGameStore((state) => state.cevdetAnim);
  const unlocked = useGameStore((state) => state.unlockedClueIds);
  const [mapOpen, setMapOpen] = useState(false);
  const arrest = arrestUnlocked(unlocked);

  function go(scene: SceneId) {
    setMapOpen(false);
    travel(scene);
  }

  return (
    <View style={styles.stage}>
      <View style={styles.wall}>
        <View style={styles.map}>
          <Text style={styles.mapTitle}>ANKARA</Text>
          <Text style={styles.mapSub}>Vadi Kule işaretli</Text>
        </View>
        <Pressable accessibilityLabel="Mantar pano" onPress={() => openTablet('board')} style={styles.cork}>
          <Text style={styles.corkTitle}>KANIT</Text>
          <Text style={styles.corkSub}>Mantar pano</Text>
        </Pressable>
      </View>
      <View style={styles.desks}>
        <View style={styles.desk} />
        <View style={styles.desk} />
        <View style={styles.desk} />
        <View style={[styles.desk, styles.deskActive]} />
      </View>
      <Pressable accessibilityLabel="Cevdet'in masası" onPress={brief} style={styles.cevdetRow}>
        <CharacterAvatarRig
          config={CHARACTERS.cevdet}
          anim={cevdetAnim}
          pose="sit"
          size={96}
          label="Cevdet"
        />
        <View style={styles.teaNote}>
          <Text style={styles.teaTitle}>Başkomiserin masası</Text>
          <Text style={styles.teaSub}>Çay, dosya, brifing</Text>
        </View>
      </Pressable>
      <View style={styles.props}>
        <View style={styles.prop}>
          <Text style={styles.propText}>Semaver</Text>
        </View>
        <View style={styles.prop}>
          <Text style={styles.propText}>Telsiz şarj</Text>
        </View>
      </View>
      <Pressable accessibilityLabel="Çıkış kapısı" onPress={() => setMapOpen(true)} style={styles.door}>
        <Text style={styles.doorText}>Çıkış kapısı</Text>
      </Pressable>
      {mapOpen ? (
        <View style={styles.sheet}>
          <Text style={styles.sheetTitle}>Nereye?</Text>
          <Pressable accessibilityLabel="Şantiye" onPress={() => go('site')} style={styles.choice}>
            <Text style={styles.choiceText}>Olay yeri — Vadi Kule</Text>
          </Pressable>
          <Pressable accessibilityLabel="Sorgu odası" onPress={() => go('interrogation')} style={styles.choice}>
            <Text style={[styles.choiceText, !arrest && styles.locked]}>
              {arrest ? 'Sorgu odası' : 'Sorgu odası kilitli'}
            </Text>
          </Pressable>
          <Pressable accessibilityLabel="Haritayı kapat" onPress={() => setMapOpen(false)}>
            <Text style={styles.cancel}>Kal</Text>
          </Pressable>
        </View>
      ) : null}
      <DialogueBar line={dialogue} />
    </View>
  );
}

const styles = StyleSheet.create({
  stage: { flex: 1, backgroundColor: '#1a140f', padding: 12, gap: 10 },
  wall: { flexDirection: 'row', gap: 10 },
  map: {
    flex: 1,
    backgroundColor: '#243044',
    minHeight: 72,
    padding: 8,
    borderWidth: 2,
    borderColor: '#8d6b3a',
  },
  mapTitle: { color: colors.paper, fontFamily: fontDisplay, fontSize: 16 },
  mapSub: { color: colors.muted, fontSize: 12 },
  cork: { flex: 1, backgroundColor: colors.cork, minHeight: 72, padding: 8 },
  corkTitle: { color: colors.paper, fontFamily: fontDisplay, letterSpacing: 2 },
  corkSub: { color: colors.paper, fontSize: 12 },
  desks: { flexDirection: 'row', gap: 6 },
  desk: { flex: 1, height: 18, backgroundColor: '#5c4634', borderTopWidth: 3, borderTopColor: '#8a7058' },
  deskActive: { borderTopColor: colors.lamp },
  cevdetRow: { flexDirection: 'row', alignItems: 'center', gap: 8, backgroundColor: '#241910', padding: 8 },
  teaNote: { flex: 1, gap: 4 },
  teaTitle: { color: colors.ink, fontFamily: fontDisplay, fontSize: 16 },
  teaSub: { color: colors.muted, fontSize: 12 },
  props: { flexDirection: 'row', gap: 8 },
  prop: { paddingHorizontal: 10, paddingVertical: 8, backgroundColor: '#3a2a22' },
  propText: { color: colors.paper, fontSize: 12 },
  door: { backgroundColor: '#3d2a1c', paddingVertical: 12, alignItems: 'center', borderWidth: 1, borderColor: colors.lampDim },
  doorText: { color: colors.lamp, fontSize: 16 },
  sheet: { backgroundColor: colors.night, padding: 12, gap: 8, borderWidth: 1, borderColor: colors.line },
  sheetTitle: { color: colors.ink, fontFamily: fontDisplay, fontSize: 18 },
  choice: { backgroundColor: colors.nightRaised, padding: 12 },
  choiceText: { color: colors.ink, fontSize: 15 },
  locked: { color: colors.muted },
  cancel: { color: colors.muted, textAlign: 'center', padding: 6 },
});
