import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';
import Svg, { Circle, Ellipse, Line, Path, Rect } from 'react-native-svg';
import type { CharacterAnimState, CharacterModelConfig, Pose } from '../engine/types';
import { colors, fontDisplay } from '../theme/colors';

type Props = {
  config: CharacterModelConfig;
  anim?: CharacterAnimState;
  pose?: Pose;
  showEkg?: boolean;
  bpm?: number;
  size?: number;
  label?: string;
};

export function CharacterAvatarRig({
  config,
  anim = config.currentAnimState,
  pose = 'stand',
  showEkg = false,
  bpm,
  size = 112,
  label,
}: Props) {
  const breathe = useSharedValue(0);
  const tilt = useSharedValue(0);
  const hop = useSharedValue(0);
  const [blink, setBlink] = useState(true);

  useEffect(() => {
    breathe.value = withRepeat(withTiming(1, { duration: 1500 }), -1, true);
  }, [breathe]);

  useEffect(() => {
    if (anim === 'ARROGANT') {
      tilt.value = withTiming(-8, { duration: 280 });
      hop.value = withTiming(0);
      return;
    }
    if (anim === 'BROKEN_CONFESS') {
      tilt.value = withTiming(18, { duration: 400 });
      hop.value = withTiming(16, { duration: 400 });
      return;
    }
    if (anim === 'ANGRY_SLAM') {
      tilt.value = withSequence(
        withTiming(10, { duration: 70 }),
        withTiming(-4, { duration: 120 }),
        withTiming(0, { duration: 160 }),
      );
      hop.value = withSequence(withTiming(18, { duration: 70 }), withTiming(0, { duration: 180 }));
      return;
    }
    if (anim === 'NERVOUS_SWEAT') {
      tilt.value = withRepeat(withTiming(3, { duration: 80 }), -1, true);
      hop.value = withTiming(0);
      return;
    }
    if (anim === 'TALKING') {
      tilt.value = withRepeat(withTiming(2, { duration: 220 }), -1, true);
      hop.value = withRepeat(withTiming(-4, { duration: 220 }), -1, true);
      return;
    }
    tilt.value = withTiming(0, { duration: 200 });
    hop.value = withTiming(0, { duration: 200 });
  }, [anim, hop, tilt]);

  useEffect(() => {
    const speed = anim === 'NERVOUS_SWEAT' || anim === 'ANGRY_SLAM' ? 260 : 1700;
    const id = setInterval(() => setBlink((open) => !open), speed);
    return () => clearInterval(id);
  }, [anim]);

  const motion = useAnimatedStyle(() => ({
    transform: [
      { translateY: hop.value },
      { rotate: `${tilt.value}deg` },
      { scaleY: 1 + breathe.value * 0.035 },
    ],
  }));

  const rate = bpm ?? config.heartRateBpm;
  const sweaty = anim === 'NERVOUS_SWEAT' || anim === 'ANGRY_SLAM' || anim === 'BROKEN_CONFESS';
  const eyesClosed = anim === 'BROKEN_CONFESS' || !blink;
  const leg = pose === 'kneel' ? 16 : pose === 'sit' ? 26 : 46;

  return (
    <View style={[styles.wrap, { width: size }]} pointerEvents="none">
      <Animated.View style={[styles.figure, pose === 'kneel' && styles.kneel, motion]}>
        <Svg width={size} height={size * 1.55} viewBox="0 0 120 210">
          <Ellipse cx="60" cy="198" rx="28" ry="6" fill="#000" opacity={0.35} />
          <Rect x="38" y="150" width="16" height={leg} rx="6" fill="#1b1b1b" />
          <Rect x="66" y="150" width="16" height={leg} rx="6" fill="#1b1b1b" />
          <Rect x="34" y="78" width="52" height="78" rx="16" fill={config.primaryColor} />
          <Rect x="46" y="78" width="28" height="22" rx="6" fill={config.secondaryColor} />
          {config.modelType === 'FORENSIC' || config.modelType === 'SITE_CHIEF' ? (
            <Rect x="36" y="96" width="48" height="8" rx="2" fill="#f2f2f2" opacity={0.85} />
          ) : null}
          {config.modelType === 'CRIMINAL_BOSS' ? (
            <Rect x="56" y="84" width="8" height="36" rx="2" fill={config.secondaryColor} />
          ) : null}
          {anim === 'BROKEN_CONFESS' ? (
            <Path
              d="M42 96 Q28 58 52 50 M78 96 Q94 58 70 50"
              stroke={colors.skin}
              strokeWidth="9"
              strokeLinecap="round"
              fill="none"
            />
          ) : (
            <>
              <Path
                d="M40 96 Q22 120 30 148"
                stroke={colors.skin}
                strokeWidth="8"
                strokeLinecap="round"
                fill="none"
              />
              <Path
                d={anim === 'ANGRY_SLAM' ? 'M80 96 Q108 130 96 168' : 'M80 96 Q100 124 92 150'}
                stroke={colors.skin}
                strokeWidth="8"
                strokeLinecap="round"
                fill="none"
              />
            </>
          )}
          {anim === 'ANGRY_SLAM' ? <Circle cx="96" cy="172" r="9" fill={config.primaryColor} /> : null}
          <Circle cx="60" cy="52" r="24" fill={colors.skin} />
          {config.accessory === 'HARD_HAT' ? (
            <Path d="M32 48 Q60 18 88 48 L84 54 Q60 36 36 54 Z" fill="#f0c419" />
          ) : null}
          {config.modelType === 'FORENSIC' ? (
            <Path d="M38 40 Q60 8 86 36 L80 48 Q60 28 42 48 Z" fill="#3a3228" />
          ) : null}
          {config.modelType === 'CRIMINAL_BOSS' ? (
            <Path d="M38 46 Q60 22 84 40 L80 50 Q60 38 40 52 Z" fill="#141414" />
          ) : null}
          {config.accessory === 'TEA_GLASS' ? (
            <Path d="M36 34 Q60 22 84 34 L78 46 Q60 36 42 46 Z" fill="#2a211c" />
          ) : null}
          {config.modelType === 'POLICE' && config.accessory === 'BADGE' ? (
            <Path d="M40 36 Q60 24 80 36 L76 46 Q60 38 44 46 Z" fill="#222" />
          ) : null}
          {eyesClosed ? (
            <>
              <Line x1="46" y1="50" x2="54" y2="50" stroke="#2b211c" strokeWidth="2" />
              <Line x1="66" y1="50" x2="74" y2="50" stroke="#2b211c" strokeWidth="2" />
            </>
          ) : (
            <>
              <Circle cx="50" cy="50" r={anim === 'NERVOUS_SWEAT' ? 3.2 : 2.4} fill="#1a120e" />
              <Circle cx="70" cy="50" r={anim === 'ARROGANT' ? 2 : 2.4} fill="#1a120e" />
            </>
          )}
          {anim === 'TALKING' || anim === 'ANGRY_SLAM' ? (
            <Ellipse cx="60" cy="66" rx="6" ry="4" fill="#6a3030" />
          ) : anim === 'BROKEN_CONFESS' ? (
            <Path d="M50 68 Q60 60 70 68" stroke="#6a3030" strokeWidth="2" fill="none" />
          ) : (
            <Path d="M50 66 Q60 72 70 66" stroke="#6a3030" strokeWidth="2" fill="none" />
          )}
          {config.accessory === 'TEA_GLASS' ? (
            <Ellipse cx="60" cy="74" rx="10" ry="6" fill="#3a2a24" opacity={0.85} />
          ) : null}
          {sweaty ? (
            <>
              <Ellipse cx="84" cy="58" rx="3" ry="5" fill="#9fd7ff" opacity={blink ? 0.95 : 0.35} />
              <Ellipse cx="90" cy="72" rx="2.4" ry="4" fill="#9fd7ff" opacity={blink ? 0.4 : 0.9} />
            </>
          ) : null}
          <Accessory config={config} />
        </Svg>
      </Animated.View>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      {showEkg ? <EkgTrace bpm={rate} /> : null}
    </View>
  );
}

function Accessory({ config }: { config: CharacterModelConfig }) {
  if (config.accessory === 'TEA_GLASS') {
    return (
      <>
        <Path d="M26 118 L34 146 L42 118" stroke="#d8c7a1" strokeWidth="3" fill="none" />
        <Path d="M30 128 L38 140" stroke={colors.tea} strokeWidth="4" />
      </>
    );
  }
  if (config.accessory === 'CAMERA') {
    return (
      <>
        <Rect x="18" y="112" width="22" height="16" rx="3" fill="#111" />
        <Circle cx="29" cy="120" r="4" fill="#9ecbff" />
      </>
    );
  }
  if (config.accessory === 'GOLD_WATCH') {
    return <Circle cx="98" cy="132" r="5" fill={config.secondaryColor} />;
  }
  if (config.accessory === 'BADGE') {
    return <Path d="M52 108 L60 102 L68 108 L66 120 L60 124 L54 120 Z" fill="#e6b450" />;
  }
  return <Rect x="46" y="168" width="28" height="8" rx="2" fill="#f0c419" />;
}

function EkgTrace({ bpm }: { bpm: number }) {
  const [phase, setPhase] = useState(0);
  useEffect(() => {
    const wait = Math.max(46, 230 - bpm);
    const id = setInterval(() => setPhase((value) => (value + 1) % 36), wait);
    return () => clearInterval(id);
  }, [bpm]);
  const beat = Math.max(8, Math.round(18 - bpm / 20));
  return (
    <View style={styles.ekg}>
      <Text style={styles.bpm}>{bpm} BPM</Text>
      <View style={styles.trace}>
        {Array.from({ length: 28 }, (_, index) => {
          const slot = (index + phase) % beat;
          const height = slot === 2 ? 6 : slot === 3 ? 22 : slot === 4 ? 4 : 8;
          return <View key={index} style={[styles.bar, { height }]} />;
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center' },
  figure: { transformOrigin: '50% 100%' },
  kneel: { marginTop: 18 },
  label: {
    color: colors.ink,
    fontFamily: fontDisplay,
    fontSize: 12,
    marginTop: 2,
  },
  ekg: {
    marginTop: 4,
    width: '100%',
    backgroundColor: '#07140c',
    borderColor: colors.crt,
    borderWidth: 1,
    padding: 4,
  },
  bpm: { color: colors.crt, fontSize: 11, fontWeight: '700' },
  trace: { flexDirection: 'row', alignItems: 'flex-end', height: 24, gap: 2 },
  bar: { width: 3, backgroundColor: colors.crt, borderRadius: 1 },
});
