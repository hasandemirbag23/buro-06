import { useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { DialogueBar } from '../components/shared/DialogueBar';
import type { CharacterAnimState } from '../engine/types';
import { useGameStore } from '../engine/useGameStore';
import { CHARACTERS, EPISODE } from '../scenarios/episode_01';
import { colors, fontDisplay } from '../theme/colors';
import { CharacterAvatarRig } from './CharacterAvatarRig';

export function CrimeSceneView() {
  const inspectHotspot = useGameStore((state) => state.inspectHotspot);
  const inspected = useGameStore((state) => state.inspectedHotspotIds);
  const dialogue = useGameStore((state) => state.dialogue);
  const [box, setBox] = useState({ w: 320, h: 520 });
  const [focus, setFocus] = useState<string | null>(null);
  const [kneel, setKneel] = useState(false);
  const [flash, setFlash] = useState(false);

  useEffect(() => {
    if (!kneel) return;
    const id = setTimeout(() => setKneel(false), 1200);
    return () => clearTimeout(id);
  }, [kneel]);

  const cevdetAnim: CharacterAnimState =
    dialogue?.speaker === 'Başkomiser Cevdet' ? 'TALKING' : 'IDLE';
  const akbabaAnim: CharacterAnimState = dialogue?.speaker === 'Akbaba' ? 'TALKING' : 'IDLE';

  function inspect(id: string) {
    setFocus(id);
    setKneel(true);
    if (id === 'hotspot_column') {
      setFlash(true);
      setTimeout(() => setFlash(false), 180);
    }
    inspectHotspot(id);
  }

  return (
    <View style={styles.stage} onLayout={(event) => setBox({ w: event.nativeEvent.layout.width, h: event.nativeEvent.layout.height })}>
      <View style={styles.sky} />
      <View style={styles.building} />
      <View style={styles.ground} />
      <View style={styles.tape}>
        <Text style={styles.tapeText}>POLİS ŞERİDİ  ·  POLİS ŞERİDİ  ·  POLİS ŞERİDİ</Text>
      </View>
      <View style={styles.column}>
        <View style={styles.crack} />
      </View>
      <View style={styles.container}>
        <Text style={styles.containerText}>ŞANTİYE OFİSİ</Text>
      </View>
      <View style={styles.chalk} />
      <View style={styles.tracks} />
      <View style={styles.car} />
      <Light wash={colors.policeRed} phase={0} />
      <Light wash={colors.policeBlue} phase={1} />
      <Rain />
      <View style={[styles.actor, { left: box.w * 0.08, top: box.h * 0.4 }]}>
        <CharacterAvatarRig config={CHARACTERS.akbaba} anim={akbabaAnim} size={84} label="Akbaba" />
      </View>
      <View style={[styles.actor, { left: box.w * 0.78, top: box.h * 0.42 }]}>
        <CharacterAvatarRig config={CHARACTERS.cevdet} anim={cevdetAnim} size={84} label="Cevdet" />
      </View>
      <View style={[styles.actor, { left: box.w * 0.4, top: box.h * 0.62 }]}>
        <CharacterAvatarRig
          config={CHARACTERS.player}
          anim={kneel ? 'IDLE' : 'IDLE'}
          pose={kneel ? 'kneel' : 'stand'}
          size={78}
          label="Komiser"
        />
      </View>
      {EPISODE.hotspots.map((spot) => {
        const done = inspected.includes(spot.id);
        return (
          <Pressable
            key={spot.id}
            accessibilityLabel={spot.title}
            onPress={() => inspect(spot.id)}
            style={[
              styles.pin,
              done && styles.pinDone,
              { left: (spot.position.x / 100) * box.w - 46, top: (spot.position.y / 100) * box.h - 18 },
            ]}
          >
            <Text style={styles.pinIcon}>{done ? '✓' : spot.icon}</Text>
            <Text style={styles.pinTitle}>{spot.title}</Text>
          </Pressable>
        );
      })}
      {focus ? <Inset id={focus} /> : null}
      {flash ? <View style={styles.flash} pointerEvents="none" /> : null}
      <View style={styles.dialogue}>
        <DialogueBar line={dialogue} />
      </View>
    </View>
  );
}

function Inset({ id }: { id: string }) {
  if (id === 'hotspot_desk') {
    return (
      <View style={styles.inset} pointerEvents="none">
        <Text style={styles.insetKicker}>TAKVİM</Text>
        <Text style={styles.insetBig}>19.03</Text>
        <Text style={styles.insetSub}>Beşiktaş kupası masada</Text>
      </View>
    );
  }
  if (id === 'hotspot_suv') {
    return (
      <View style={styles.inset} pointerEvents="none">
        <Text style={styles.insetKicker}>KULE KAMERASI</Text>
        <Text style={styles.insetBig}>06 KZY 44</Text>
        <Text style={styles.insetSub}>Siyah SUV, çamurda kalın lastik</Text>
      </View>
    );
  }
  if (id === 'hotspot_column') {
    return (
      <View style={styles.inset} pointerEvents="none">
        <Text style={styles.insetKicker}>NUMUNE</Text>
        <Text style={styles.insetSub}>Çatlak kolon, demir eksik. Akbaba poşeti kapattı.</Text>
      </View>
    );
  }
  return (
    <View style={styles.inset} pointerEvents="none">
      <Text style={styles.insetKicker}>DELİL POŞETİ</Text>
      <Text style={styles.insetSub}>Kırık ekranlı telefon envantere girdi.</Text>
    </View>
  );
}

function Light({ wash, phase }: { wash: string; phase: number }) {
  const glow = useSharedValue(phase);
  useEffect(() => {
    glow.value = withRepeat(withTiming(phase === 0 ? 1 : 0, { duration: 700 }), -1, true);
  }, [glow, phase]);
  const style = useAnimatedStyle(() => ({ opacity: phase === 0 ? glow.value : 1 - glow.value }));
  return <Animated.View pointerEvents="none" style={[styles.wash, { backgroundColor: wash }, style]} />;
}

function Rain() {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {Array.from({ length: 18 }, (_, index) => (
        <Drop key={index} left={(index * 37) % 100} delay={index * 90} />
      ))}
    </View>
  );
}

function Drop({ left, delay }: { left: number; delay: number }) {
  const y = useSharedValue(-30);
  useEffect(() => {
    y.value = withDelay(delay, withRepeat(withTiming(640, { duration: 900 + (left % 5) * 80 }), -1, false));
  }, [delay, left, y]);
  const style = useAnimatedStyle(() => ({ transform: [{ translateY: y.value }] }));
  return <Animated.View style={[styles.drop, { left: `${left}%` }, style]} />;
}

const styles = StyleSheet.create({
  stage: { flex: 1, backgroundColor: '#070b12', overflow: 'hidden' },
  sky: { ...StyleSheet.absoluteFill, backgroundColor: '#10182a' },
  building: {
    position: 'absolute',
    left: '8%',
    top: '6%',
    width: '46%',
    height: '38%',
    backgroundColor: '#1b2433',
    borderWidth: 2,
    borderColor: '#2c3a52',
  },
  ground: { position: 'absolute', left: 0, right: 0, bottom: 0, height: '46%', backgroundColor: colors.mud },
  tape: {
    position: 'absolute',
    top: '48%',
    left: 0,
    right: 0,
    backgroundColor: colors.caution,
    paddingVertical: 3,
  },
  tapeText: { color: '#1a1408', fontSize: 11, fontWeight: '700', letterSpacing: 1 },
  column: {
    position: 'absolute',
    left: '8%',
    top: '28%',
    width: 36,
    height: 120,
    backgroundColor: '#9aa0a6',
  },
  crack: {
    position: 'absolute',
    left: 14,
    top: 20,
    width: 3,
    height: 70,
    backgroundColor: '#2b3138',
    transform: [{ rotate: '12deg' }],
  },
  container: {
    position: 'absolute',
    right: '6%',
    top: '18%',
    width: 110,
    height: 64,
    backgroundColor: '#3e4a3a',
    borderWidth: 2,
    borderColor: '#6d7a55',
    justifyContent: 'center',
  },
  containerText: { color: colors.paper, fontSize: 10, textAlign: 'center' },
  chalk: {
    position: 'absolute',
    left: '22%',
    top: '64%',
    width: 70,
    height: 28,
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.75)',
    borderRadius: 20,
  },
  tracks: {
    position: 'absolute',
    right: '18%',
    top: '60%',
    width: 90,
    height: 16,
    borderBottomWidth: 4,
    borderStyle: 'dashed',
    borderColor: '#5a4a32',
  },
  car: {
    position: 'absolute',
    left: '46%',
    top: '50%',
    width: 54,
    height: 26,
    backgroundColor: '#15191f',
    borderRadius: 4,
  },
  wash: { ...StyleSheet.absoluteFill, opacity: 0.18 },
  actor: { position: 'absolute' },
  pin: {
    position: 'absolute',
    width: 92,
    backgroundColor: 'rgba(12,16,22,0.88)',
    borderColor: colors.lamp,
    borderWidth: 1,
    padding: 4,
  },
  pinDone: { borderColor: colors.ok },
  pinIcon: { color: colors.ink, fontSize: 14 },
  pinTitle: { color: colors.ink, fontSize: 11 },
  inset: {
    position: 'absolute',
    left: 12,
    top: 12,
    right: 12,
    backgroundColor: colors.paper,
    padding: 10,
    zIndex: 4,
  },
  insetKicker: { color: colors.tea, fontSize: 11, letterSpacing: 1 },
  insetBig: { color: colors.paperInk, fontFamily: fontDisplay, fontSize: 28 },
  insetSub: { color: colors.paperInk, fontSize: 13 },
  flash: { ...StyleSheet.absoluteFill, backgroundColor: '#fff' },
  dialogue: { position: 'absolute', left: 8, right: 8, bottom: 8, zIndex: 5 },
  drop: {
    position: 'absolute',
    top: 0,
    width: 1,
    height: 14,
    backgroundColor: 'rgba(180,200,230,0.45)',
  },
});
