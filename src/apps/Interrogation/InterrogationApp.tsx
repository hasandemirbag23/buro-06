import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { EvidencePickerModal } from '../../components/shared/EvidencePickerModal';
import { caseIsClosed, useGameStore } from '../../engine/useGameStore';
import { EPISODE } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

export function InterrogationApp() {
  const activeSuspect = useGameStore((state) => state.activeSuspect);
  const selectSuspect = useGameStore((state) => state.selectSuspect);
  const stress = useGameStore((state) => state.stress);
  const bpm = useGameStore((state) => state.bpm);
  const confessed = useGameStore((state) => state.confessed);
  const used = useGameStore((state) => state.usedBySuspect);
  const ids = useGameStore((state) => state.unlockedClueIds);
  const slamEvidence = useGameStore((state) => state.slamEvidence);
  const openCaseReport = useGameStore((state) => state.openCaseReport);
  const [picker, setPicker] = useState(false);
  const closed = caseIsClosed(confessed);
  const stressNow = activeSuspect ? stress[activeSuspect] : 0;
  const bpmNow = activeSuspect ? bpm[activeSuspect] : 75;

  return (
    <View style={styles.panel}>
      <View style={styles.row}>
        {EPISODE.suspects.map((suspect) => (
          <Pressable
            key={suspect.id}
            accessibilityLabel={suspect.character.name}
            onPress={() => selectSuspect(suspect.id)}
            style={[styles.suspect, activeSuspect === suspect.id && styles.suspectOn]}
          >
            <Text style={styles.suspectText}>
              {suspect.character.name}
              {confessed[suspect.id] ? ' · itiraf' : ''}
            </Text>
          </Pressable>
        ))}
      </View>
      <View style={styles.meter}>
        <Text style={styles.bpm}>{bpmNow} BPM</Text>
        <View style={styles.track}>
          <View style={[styles.fill, { width: `${stressNow}%` }]} />
        </View>
        <Text style={styles.stress}>Stres %{stressNow}</Text>
      </View>
      <Pressable accessibilityLabel="Kanıtı masaya vur" onPress={() => setPicker(true)} style={styles.slam}>
        <Text style={styles.slamText}>Kanıtı masaya vur</Text>
      </Pressable>
      {closed ? (
        <Pressable accessibilityLabel="Tutanağı aç" onPress={openCaseReport}>
          <Text style={styles.report}>Dosya kapandı — tutanağı aç</Text>
        </Pressable>
      ) : null}
      <EvidencePickerModal
        visible={picker}
        clueIds={ids}
        usedIds={activeSuspect ? used[activeSuspect] : []}
        onClose={() => setPicker(false)}
        onPick={(clueId) => {
          setPicker(false);
          slamEvidence(clueId);
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  panel: { flex: 1, padding: 8, gap: 8, backgroundColor: '#0e0c0a' },
  row: { flexDirection: 'row', gap: 6 },
  suspect: { flex: 1, padding: 8, borderWidth: 1, borderColor: colors.line, alignItems: 'center' },
  suspectOn: { borderColor: colors.lamp, backgroundColor: '#241c12' },
  suspectText: { color: colors.ink, fontSize: 13 },
  meter: { gap: 4 },
  bpm: { color: colors.crt, fontFamily: fontDisplay, fontSize: 16 },
  track: { height: 8, backgroundColor: '#2a211c' },
  fill: { height: 8, backgroundColor: colors.danger },
  stress: { color: colors.muted, fontSize: 12 },
  slam: { backgroundColor: colors.policeRed, paddingVertical: 10, alignItems: 'center' },
  slamText: { color: '#fff', fontWeight: '700' },
  report: { color: colors.lamp, textAlign: 'center' },
});
