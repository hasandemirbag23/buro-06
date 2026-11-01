import { StyleSheet, Text, View } from 'react-native';
import type { DialogueLine } from '../../engine/types';
import { colors, fontDisplay } from '../../theme/colors';

export function DialogueBar({ line }: { line: DialogueLine | null }) {
  if (!line) return null;
  return (
    <View style={styles.bar} accessibilityRole="text">
      <Text style={styles.speaker}>{line.speaker}</Text>
      <Text style={styles.text}>{line.text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    backgroundColor: 'rgba(8,10,14,0.92)',
    borderColor: colors.lampDim,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
    gap: 2,
  },
  speaker: {
    color: colors.lamp,
    fontFamily: fontDisplay,
    fontSize: 13,
  },
  text: { color: colors.ink, fontSize: 14, lineHeight: 19 },
});
