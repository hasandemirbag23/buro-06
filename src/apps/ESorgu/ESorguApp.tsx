import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { colors, fontDisplay } from '../../theme/colors';

export function ESorguApp() {
  const searchEsorgu = useGameStore((state) => state.searchEsorgu);
  const history = useGameStore((state) => state.esorguHistory);
  const ids = useGameStore((state) => state.unlockedClueIds);
  const [query, setQuery] = useState('');
  const hints = [
    ids.includes('clue_suv_photo') ? '06 KZY 44' : null,
    ids.includes('clue_bank_500k') || ids.includes('clue_company_record') ? 'Kuzey Hafriyat' : null,
    ids.includes('clue_company_record') || ids.includes('clue_pts_06kzy44') ? 'Tarık Soylu' : null,
  ].filter((hint): hint is string => Boolean(hint));

  return (
    <ScrollView contentContainerStyle={styles.screen} keyboardShouldPersistTaps="handled">
      <Text style={styles.kicker}>GBT · PTS · HTS</Text>
      <Text style={styles.title}>E-Sorgu</Text>
      <TextInput
        accessibilityLabel="E-Sorgu alanı"
        value={query}
        onChangeText={setQuery}
        onSubmitEditing={() => searchEsorgu(query)}
        placeholder="Şirket, plaka veya isim"
        placeholderTextColor={colors.muted}
        style={styles.input}
        autoCapitalize="characters"
        autoCorrect={false}
      />
      <Pressable accessibilityLabel="Sorgula" onPress={() => searchEsorgu(query)} style={styles.button}>
        <Text style={styles.buttonText}>Sorgula</Text>
      </Pressable>
      <View style={styles.hints}>
        {hints.map((hint) => (
          <Pressable key={hint} accessibilityLabel={hint} onPress={() => setQuery(hint)} style={styles.chip}>
            <Text style={styles.chipText}>{hint}</Text>
          </Pressable>
        ))}
      </View>
      {history.map((hit, index) => (
        <View key={`${hit.query}-${index}`} style={styles.card}>
          <Text style={styles.query}>{hit.query}</Text>
          <Text style={[styles.cardTitle, !hit.found && styles.miss]}>{hit.title}</Text>
          <Text style={styles.body}>{hit.body}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { padding: 16, gap: 10 },
  kicker: { color: colors.crt, letterSpacing: 2, fontSize: 11 },
  title: { color: colors.crt, fontFamily: fontDisplay, fontSize: 28 },
  input: {
    borderWidth: 1,
    borderColor: colors.crt,
    color: colors.crt,
    padding: 12,
    fontSize: 16,
    backgroundColor: colors.crtDim,
  },
  button: { backgroundColor: colors.crt, padding: 12, alignItems: 'center' },
  buttonText: { color: '#06210f', fontWeight: '700' },
  hints: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { borderWidth: 1, borderColor: colors.crt, paddingHorizontal: 8, paddingVertical: 4 },
  chipText: { color: colors.crt, fontSize: 12 },
  card: { backgroundColor: colors.crtDim, padding: 12, gap: 4, borderWidth: 1, borderColor: '#1d5a32' },
  query: { color: colors.muted, fontSize: 12 },
  cardTitle: { color: colors.crt, fontSize: 16 },
  miss: { color: colors.danger },
  body: { color: colors.ink, lineHeight: 20 },
});
