import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { colors, fontDisplay } from '../../theme/colors';

const TITLES = {
  office: 'Cinayet Büro',
  site: 'Vadi Kule Şantiyesi',
  interrogation: 'Sorgu Odası',
} as const;

export function SceneHeader() {
  const scene = useGameStore((state) => state.scene);
  const count = useGameStore((state) => state.unlockedClueIds.length);
  const travel = useGameStore((state) => state.travel);
  return (
    <View style={styles.bar}>
      <Text style={styles.title}>{TITLES[scene]}</Text>
      <Text style={styles.count}>{count} kanıt</Text>
      {scene !== 'office' ? (
        <Pressable accessibilityLabel="Ofise dön" onPress={() => travel('office')}>
          <Text style={styles.link}>Ofise dön</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#05070b',
  },
  title: { color: colors.ink, fontFamily: fontDisplay, fontSize: 16, flex: 1 },
  count: { color: colors.muted, fontSize: 12 },
  link: { color: colors.lamp, fontSize: 13 },
});
