import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, fontDisplay } from '../../theme/colors';

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'];

export function PinKeypad({
  error,
  onSubmit,
}: {
  error: boolean;
  onSubmit: (pin: string) => void;
}) {
  const [pin, setPin] = useState('');

  function press(key: string) {
    if (key === 'C' || key === '⌫') {
      setPin('');
      return;
    }
    const next = (pin + key).slice(0, 4);
    setPin(next);
    if (next.length === 4) {
      onSubmit(next);
      setPin('');
    }
  }

  return (
    <View style={styles.wrap}>
      <Text style={styles.dots}>{pin.padEnd(4, '·')}</Text>
      {error ? <Text style={styles.err}>Hatalı şifre</Text> : <Text style={styles.err}> </Text>}
      <View style={styles.grid}>
        {KEYS.map((key) => (
          <Pressable
            key={key}
            accessibilityLabel={key === '⌫' || key === 'C' ? 'Sil' : `Tuş ${key}`}
            onPress={() => press(key)}
            style={styles.key}
          >
            <Text style={styles.keyText}>{key}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center', gap: 8 },
  dots: {
    color: colors.ink,
    fontFamily: fontDisplay,
    fontSize: 28,
    letterSpacing: 8,
  },
  err: { color: colors.danger, minHeight: 18 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', width: 240, justifyContent: 'center' },
  key: {
    width: 68,
    height: 52,
    margin: 4,
    borderRadius: 8,
    backgroundColor: colors.nightRaised,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: colors.line,
  },
  keyText: { color: colors.ink, fontSize: 20 },
});
