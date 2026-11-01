import { Modal, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { clueById } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

export function EvidencePickerModal({
  visible,
  clueIds,
  usedIds,
  onClose,
  onPick,
}: {
  visible: boolean;
  clueIds: string[];
  usedIds: string[];
  onClose: () => void;
  onPick: (clueId: string) => void;
}) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.backdrop}>
        <View style={styles.sheet}>
          <Text style={styles.title}>Masaya vurulacak kanıt</Text>
          <ScrollView style={styles.list}>
            {clueIds.length === 0 ? (
              <Text style={styles.empty}>Envanter boş. Önce şantiyeyi ve tableti tara.</Text>
            ) : (
              clueIds.map((id) => {
                const clue = clueById(id);
                if (!clue) return null;
                const used = usedIds.includes(id);
                return (
                  <Pressable
                    key={id}
                    accessibilityLabel={clue.title}
                    onPress={() => onPick(id)}
                    style={[styles.row, used && styles.used]}
                  >
                    <Text style={styles.icon}>{clue.icon}</Text>
                    <View style={styles.copy}>
                      <Text style={styles.name}>{clue.title}</Text>
                      <Text style={styles.meta}>{used ? 'Masaya vuruldu' : clue.summary}</Text>
                    </View>
                  </Pressable>
                );
              })
            )}
          </ScrollView>
          <Pressable accessibilityLabel="Kanıt seçimini kapat" onPress={onClose} style={styles.close}>
            <Text style={styles.closeText}>Kapat</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.66)', justifyContent: 'flex-end' },
  sheet: {
    maxHeight: '78%',
    backgroundColor: colors.nightRaised,
    padding: 16,
    gap: 10,
    borderTopWidth: 2,
    borderTopColor: colors.lamp,
  },
  title: { color: colors.lamp, fontFamily: fontDisplay, fontSize: 20 },
  list: { flexGrow: 0 },
  empty: { color: colors.muted, paddingVertical: 12 },
  row: {
    flexDirection: 'row',
    gap: 10,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  used: { opacity: 0.45 },
  icon: { fontSize: 22 },
  copy: { flex: 1, gap: 2 },
  name: { color: colors.ink, fontSize: 15 },
  meta: { color: colors.muted, fontSize: 12 },
  close: { alignItems: 'center', paddingVertical: 10 },
  closeText: { color: colors.ink },
});
