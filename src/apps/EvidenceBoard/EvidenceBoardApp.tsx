import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { clueById } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

const GROUPS = [
  {
    title: 'Olay yeri',
    ids: ['clue_victim_phone', 'clue_desk_photo', 'clue_cracked_column', 'clue_suv_photo'],
  },
  {
    title: 'Telefon',
    ids: ['clue_bank_500k', 'clue_concrete_report', 'clue_zafer_sms', 'clue_no_suicide'],
  },
  {
    title: 'E-Sorgu',
    ids: ['clue_company_record', 'clue_pts_06kzy44', 'clue_hts_tarik'],
  },
];

export function EvidenceBoardApp() {
  const ids = useGameStore((state) => state.unlockedClueIds);
  return (
    <ScrollView contentContainerStyle={styles.screen}>
      <Text style={styles.title}>Kanıt panosu</Text>
      {ids.length === 0 ? <Text style={styles.empty}>Henüz iğne yok. Şantiyeye çık.</Text> : null}
      {GROUPS.map((group) => (
        <View key={group.title} style={styles.group}>
          <Text style={styles.groupTitle}>{group.title}</Text>
          <View style={styles.notes}>
            {group.ids.map((id) => {
              const clue = clueById(id);
              const open = ids.includes(id);
              return (
                <View key={id} style={[styles.note, !open && styles.blank]}>
                  <Text style={styles.noteTitle}>{open && clue ? `${clue.icon} ${clue.title}` : 'Boş iğne'}</Text>
                  {open && clue ? <Text style={styles.noteBody}>{clue.summary}</Text> : null}
                </View>
              );
            })}
          </View>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { padding: 14, gap: 12, backgroundColor: colors.cork },
  title: { color: colors.paper, fontFamily: fontDisplay, fontSize: 26 },
  empty: { color: colors.paper },
  group: { gap: 8 },
  groupTitle: { color: colors.lamp, letterSpacing: 1 },
  notes: { gap: 8 },
  note: { backgroundColor: colors.paper, padding: 10, gap: 4 },
  blank: { backgroundColor: 'rgba(216,199,161,0.35)' },
  noteTitle: { color: colors.paperInk, fontSize: 14 },
  noteBody: { color: colors.paperInk, fontSize: 12, lineHeight: 17 },
});
