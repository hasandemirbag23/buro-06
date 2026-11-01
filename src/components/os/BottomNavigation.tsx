import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { colors } from '../../theme/colors';

export function BottomNavigation() {
  const layer = useGameStore((state) => state.layer);
  const setLayer = useGameStore((state) => state.setLayer);
  return (
    <View style={styles.bar}>
      <Pressable
        accessibilityLabel="Sahneye dön"
        onPress={() => setLayer('world')}
        style={[styles.btn, layer === 'world' && styles.on]}
      >
        <Text style={styles.text}>Sahne</Text>
      </Pressable>
      <Pressable
        accessibilityLabel="Görev Tabletini Aç"
        onPress={() => setLayer('tablet')}
        style={[styles.btn, layer === 'tablet' && styles.on]}
      >
        <Text style={styles.text}>Görev Tabletini Aç</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: { flexDirection: 'row', borderTopWidth: 1, borderTopColor: colors.line, backgroundColor: '#05070b' },
  btn: { flex: 1, paddingVertical: 12, alignItems: 'center' },
  on: { borderTopWidth: 2, borderTopColor: colors.lamp },
  text: { color: colors.ink, fontSize: 13 },
});
