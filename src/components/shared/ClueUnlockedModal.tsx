import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { colors, fontDisplay } from '../../theme/colors';

export function ClueUnlockedModal() {
  const clue = useGameStore((state) => state.clueModal);
  const dismissClue = useGameStore((state) => state.dismissClue);
  return (
    <Modal visible={clue !== null} transparent animationType="fade" onRequestClose={dismissClue}>
      <View style={styles.backdrop}>
        <View style={styles.card}>
          <Text style={styles.kicker}>KANIT AÇILDI</Text>
          <Text style={styles.icon}>{clue?.icon}</Text>
          <Text style={styles.title}>{clue?.title}</Text>
          <Text style={styles.body}>{clue?.summary}</Text>
          <Pressable accessibilityLabel="Dosyaya işle" onPress={dismissClue} style={styles.button}>
            <Text style={styles.buttonText}>Dosyaya işle</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.72)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    width: '100%',
    maxWidth: 360,
    backgroundColor: colors.paper,
    padding: 18,
    gap: 8,
  },
  kicker: { color: colors.tea, letterSpacing: 2, fontSize: 12 },
  icon: { fontSize: 28 },
  title: { color: colors.paperInk, fontFamily: fontDisplay, fontSize: 22 },
  body: { color: colors.paperInk, fontSize: 15, lineHeight: 21 },
  button: { backgroundColor: colors.night, paddingVertical: 12, alignItems: 'center', marginTop: 6 },
  buttonText: { color: colors.lamp, fontSize: 16 },
});
