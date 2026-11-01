import { useEffect } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withRepeat, withTiming } from 'react-native-reanimated';
import { useGameStore } from '../../engine/useGameStore';
import { colors, fontDisplay } from '../../theme/colors';

export function IncomingCallModal() {
  const call = useGameStore((state) => state.incomingCall);
  const answerCall = useGameStore((state) => state.answerCall);
  const declineCall = useGameStore((state) => state.declineCall);
  const pulse = useSharedValue(1);
  useEffect(() => {
    pulse.value = withRepeat(withTiming(1.08, { duration: 700 }), -1, true);
  }, [pulse]);
  const style = useAnimatedStyle(() => ({ transform: [{ scale: pulse.value }] }));
  if (!call) return null;
  return (
    <View style={styles.backdrop}>
      <Animated.Text style={[styles.icon, style]}>📞</Animated.Text>
      <Text style={styles.kicker}>GELEN ARAMA</Text>
      <Text style={styles.from}>{call.from}</Text>
      <Text style={styles.text}>{call.text}</Text>
      <View style={styles.row}>
        <Pressable accessibilityLabel="Kapat" onPress={declineCall} style={styles.decline}>
          <Text style={styles.btn}>Kapat</Text>
        </Pressable>
        <Pressable accessibilityLabel="Aç" onPress={answerCall} style={styles.answer}>
          <Text style={styles.btn}>Aç</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFill,
    zIndex: 30,
    backgroundColor: 'rgba(5,7,12,0.94)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 8,
  },
  icon: { fontSize: 42 },
  kicker: { color: colors.ok, letterSpacing: 2, fontSize: 12 },
  from: { color: colors.ink, fontFamily: fontDisplay, fontSize: 26, textAlign: 'center' },
  text: { color: colors.muted, textAlign: 'center', lineHeight: 20 },
  row: { flexDirection: 'row', gap: 12, marginTop: 12 },
  decline: { backgroundColor: colors.danger, paddingHorizontal: 22, paddingVertical: 12 },
  answer: { backgroundColor: '#1f7a45', paddingHorizontal: 22, paddingVertical: 12 },
  btn: { color: '#fff', fontSize: 16 },
});
