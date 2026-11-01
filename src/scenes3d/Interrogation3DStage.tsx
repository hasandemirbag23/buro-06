import { useEffect } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';
import { DialogueBar } from '../components/shared/DialogueBar';
import type { CameraFrame } from '../engine/types';
import { useGameStore } from '../engine/useGameStore';
import { CHARACTERS, clueById, suspectById } from '../scenarios/episode_01';
import { colors, fontDisplay } from '../theme/colors';
import { CharacterAvatarRig } from './CharacterAvatarRig';

const FRAMES: { id: CameraFrame; label: string }[] = [
  { id: 'wide', label: 'Geniş açı' },
  { id: 'closeup', label: 'Yakın plan' },
  { id: 'tabletop', label: 'Masa üstü' },
];

export function Interrogation3DStage() {
  const camera = useGameStore((state) => state.camera);
  const setCamera = useGameStore((state) => state.setCamera);
  const activeSuspect = useGameStore((state) => state.activeSuspect);
  const anim = useGameStore((state) => state.anim);
  const bpm = useGameStore((state) => state.bpm);
  const stress = useGameStore((state) => state.stress);
  const cevdetAnim = useGameStore((state) => state.cevdetAnim);
  const dialogue = useGameStore((state) => state.dialogue);
  const cevdetLine = useGameStore((state) => state.cevdetLine);
  const slamClueId = useGameStore((state) => state.slamClueId);
  const tableClueIds = useGameStore((state) => state.tableClueIds);
  const impactNonce = useGameStore((state) => state.impactNonce);
  const suspect = activeSuspect ? suspectById(activeSuspect) : null;
  const paper = slamClueId ? clueById(slamClueId) : undefined;

  const shake = useSharedValue(0);
  const drop = useSharedValue(-120);
  useEffect(() => {
    if (impactNonce === 0) return;
    shake.value = withSequence(
      withTiming(8, { duration: 40 }),
      withTiming(-7, { duration: 40 }),
      withTiming(4, { duration: 40 }),
      withTiming(0, { duration: 50 }),
    );
    drop.value = -120;
    drop.value = withTiming(0, { duration: 260 });
  }, [drop, impactNonce, shake]);

  const roomStyle = useAnimatedStyle(() => ({ transform: [{ translateX: shake.value }] }));
  const paperStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: drop.value }, { rotate: '-6deg' }],
  }));

  return (
    <Animated.View style={[styles.room, roomStyle]}>
      <Lamp />
      <View style={styles.pool} pointerEvents="none" />
      <View style={styles.frames}>
        {FRAMES.map((frame) => (
          <Pressable
            key={frame.id}
            accessibilityLabel={frame.label}
            onPress={() => setCamera(frame.id)}
            style={[styles.frameBtn, camera === frame.id && styles.frameOn]}
          >
            <Text style={styles.frameText}>{frame.label}</Text>
          </Pressable>
        ))}
      </View>
      {camera === 'tabletop' ? (
        <View style={styles.tabletop}>
          <Text style={styles.tableLabel}>METAL MASA</Text>
          {tableClueIds.length === 0 ? (
            <Text style={styles.empty}>Masada henüz dosya yok.</Text>
          ) : (
            tableClueIds.map((id) => {
              const clue = clueById(id);
              return clue ? (
                <View key={id} style={styles.file}>
                  <Text style={styles.fileTitle}>
                    {clue.icon} {clue.title}
                  </Text>
                </View>
              ) : null;
            })
          )}
        </View>
      ) : null}
      {camera === 'closeup' && suspect ? (
        <View style={styles.closeup}>
          <CharacterAvatarRig
            config={suspect.character}
            anim={anim[suspect.id]}
            pose="sit"
            size={150}
            showEkg
            bpm={bpm[suspect.id]}
            label={suspect.character.name}
          />
          <Text style={styles.stress}>Stres %{stress[suspect.id]}</Text>
        </View>
      ) : null}
      {camera === 'wide' ? (
        <View style={styles.wide}>
          <CharacterAvatarRig config={CHARACTERS.cevdet} anim={cevdetAnim} size={78} label="Cevdet" />
          <View style={styles.center}>
            {suspect ? (
              <CharacterAvatarRig
                config={suspect.character}
                anim={anim[suspect.id]}
                pose="sit"
                size={100}
                showEkg
                bpm={bpm[suspect.id]}
                label={suspect.character.name}
              />
            ) : (
              <Text style={styles.empty}>Sandalye boş. Şüpheli seç.</Text>
            )}
            <View style={styles.table} />
          </View>
          <CharacterAvatarRig config={CHARACTERS.player} anim="TALKING" size={78} label="Komiser" />
        </View>
      ) : null}
      {paper && camera !== 'tabletop' ? (
        <Animated.View pointerEvents="none" style={[styles.paper, paperStyle]}>
          <Text style={styles.paperText}>
            {paper.icon} {paper.title}
          </Text>
        </Animated.View>
      ) : null}
      <View style={styles.lines}>
        <DialogueBar line={dialogue} />
        {cevdetLine ? <DialogueBar line={{ speaker: 'Başkomiser Cevdet', text: cevdetLine }} /> : null}
      </View>
    </Animated.View>
  );
}

function Lamp() {
  const rot = useSharedValue(-8);
  useEffect(() => {
    rot.value = withRepeat(withTiming(8, { duration: 1300 }), -1, true);
  }, [rot]);
  const style = useAnimatedStyle(() => ({ transform: [{ rotate: `${rot.value}deg` }] }));
  return (
    <Animated.View style={[styles.lamp, style]}>
      <View style={styles.cord} />
      <View style={styles.bulb} />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  room: { flex: 1, backgroundColor: '#12100e', overflow: 'hidden' },
  pool: {
    position: 'absolute',
    left: '18%',
    top: '18%',
    width: '64%',
    height: '55%',
    backgroundColor: 'rgba(230,180,80,0.08)',
    borderRadius: 80,
  },
  lamp: {
    position: 'absolute',
    top: 0,
    alignSelf: 'center',
    alignItems: 'center',
    transformOrigin: '50% 0%',
    zIndex: 3,
  },
  cord: { width: 2, height: 36, backgroundColor: '#666' },
  bulb: {
    width: 28,
    height: 16,
    backgroundColor: colors.lamp,
    borderBottomLeftRadius: 8,
    borderBottomRightRadius: 8,
  },
  frames: { flexDirection: 'row', gap: 6, padding: 8, paddingTop: 28 },
  frameBtn: { paddingHorizontal: 8, paddingVertical: 4, borderWidth: 1, borderColor: colors.line },
  frameOn: { borderColor: colors.lamp, backgroundColor: '#2a2418' },
  frameText: { color: colors.ink, fontSize: 11 },
  wide: { flex: 1, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-around', paddingBottom: 8 },
  center: { alignItems: 'center' },
  table: { width: 120, height: 16, backgroundColor: colors.metal, marginTop: -8 },
  closeup: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  stress: { color: colors.danger, marginTop: 4, fontSize: 13 },
  tabletop: { flex: 1, margin: 16, backgroundColor: '#6e7682', padding: 12, gap: 8 },
  tableLabel: { color: '#1b1e24', letterSpacing: 2, fontSize: 11 },
  file: { backgroundColor: colors.paper, padding: 8 },
  fileTitle: { color: colors.paperInk, fontSize: 13 },
  empty: { color: colors.muted, textAlign: 'center' },
  paper: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: 78,
    backgroundColor: colors.paper,
    paddingHorizontal: 10,
    paddingVertical: 8,
    zIndex: 4,
  },
  paperText: { color: colors.paperInk, fontFamily: fontDisplay, fontSize: 13 },
  lines: { paddingHorizontal: 8, paddingBottom: 6, gap: 4 },
});
