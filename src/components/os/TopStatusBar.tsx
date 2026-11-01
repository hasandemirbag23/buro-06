import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { colors } from '../../theme/colors';

function clock() {
  return new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
}

export function TopStatusBar() {
  const count = useGameStore((state) => state.unlockedClueIds.length);
  const [now, setNow] = useState(clock);
  useEffect(() => {
    const id = setInterval(() => setNow(clock()), 10000);
    return () => clearInterval(id);
  }, []);
  return (
    <View style={styles.bar}>
      <Text style={styles.brand}>BÜRO-OS</Text>
      <Text style={styles.meta}>Dosya {count}</Text>
      <Text style={styles.meta}>{now}</Text>
      <Text style={styles.meta}>87%</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#05070b',
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  brand: { color: colors.lamp, fontWeight: '700', letterSpacing: 1 },
  meta: { color: colors.muted, fontSize: 12 },
});
