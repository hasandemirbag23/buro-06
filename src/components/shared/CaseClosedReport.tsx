import { Modal, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { clueById, EPISODE } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

export function CaseClosedReport() {
  const visible = useGameStore((state) => state.showCaseReport);
  const ids = useGameStore((state) => state.unlockedClueIds);
  const closeCaseReport = useGameStore((state) => state.closeCaseReport);
  const resetCase = useGameStore((state) => state.resetCase);
  const zafer = EPISODE.suspects[0];
  const tarik = EPISODE.suspects[1];
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={closeCaseReport}>
      <View style={styles.backdrop}>
        <View style={styles.card}>
          <ScrollView contentContainerStyle={styles.content}>
            <Text style={styles.kicker}>DOSYA NO 06</Text>
            <Text style={styles.title}>Dosya kapandı</Text>
            <Text style={styles.body}>
              Zafer, mühendisi 01:00’de 14. kata çağırdı ve C16 dökümünü örttü. Tarık Soylu, Kuzey
              Hafriyat üzerinden 500.000 TL sus payı gönderdi. 06 KZY 44 plakalı aracı ve hattı cinayet
              saatinde şantiyedeydi.
            </Text>
            <Text style={styles.sub}>{zafer.character.name}</Text>
            <Text style={styles.body}>{zafer.lines.confess}</Text>
            <Text style={styles.sub}>{tarik.character.name}</Text>
            <Text style={styles.body}>{tarik.lines.confess}</Text>
            <Text style={styles.sub}>Envanter</Text>
            {ids.map((id) => {
              const clue = clueById(id);
              return clue ? (
                <Text key={id} style={styles.clue}>
                  {clue.icon} {clue.title}
                </Text>
              ) : null;
            })}
          </ScrollView>
          <View style={styles.row}>
            <Pressable accessibilityLabel="Tutanağı kapat" onPress={closeCaseReport} style={styles.ghost}>
              <Text style={styles.ghostText}>Kapat</Text>
            </Pressable>
            <Pressable accessibilityLabel="Yeniden aç" onPress={resetCase} style={styles.solid}>
              <Text style={styles.solidText}>Yeniden aç</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.78)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 18,
  },
  card: { width: '100%', maxWidth: 380, maxHeight: '86%', backgroundColor: colors.paper },
  content: { padding: 18, gap: 8 },
  kicker: { color: colors.tea, letterSpacing: 2, fontSize: 12 },
  title: { color: colors.paperInk, fontFamily: fontDisplay, fontSize: 28 },
  sub: { color: colors.tea, fontFamily: fontDisplay, fontSize: 16, marginTop: 6 },
  body: { color: colors.paperInk, fontSize: 14, lineHeight: 20 },
  clue: { color: colors.paperInk, fontSize: 13 },
  row: { flexDirection: 'row' },
  ghost: { flex: 1, padding: 14, alignItems: 'center' },
  ghostText: { color: colors.paperInk },
  solid: { flex: 1, padding: 14, alignItems: 'center', backgroundColor: colors.night },
  solidText: { color: colors.lamp },
});
