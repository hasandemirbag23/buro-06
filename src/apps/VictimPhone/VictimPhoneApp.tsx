import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { PinKeypad } from '../../components/shared/PinKeypad';
import { useGameStore } from '../../engine/useGameStore';
import { EPISODE, phoneReady } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

export function VictimPhoneApp() {
  const ids = useGameStore((state) => state.unlockedClueIds);
  const phoneUnlocked = useGameStore((state) => state.phoneUnlocked);
  const pinError = useGameStore((state) => state.pinError);
  const tryPin = useGameStore((state) => state.tryPin);
  const openPhoneItem = useGameStore((state) => state.openPhoneItem);
  const travel = useGameStore((state) => state.travel);
  const [openId, setOpenId] = useState<string | null>(null);
  const ready = phoneReady(ids);
  const desk = ids.includes('clue_desk_photo');

  if (!ready) {
    return (
      <View style={styles.center}>
        <Text style={styles.title}>Maktulün telefonu</Text>
        <Text style={styles.body}>
          Telefon olay yerinde. Cesedin yanındaki cihaz delil poşetine girmeden bu uygulama açılmaz.
        </Text>
        <Pressable accessibilityLabel="Şantiyeye dön" onPress={() => travel('site')} style={styles.button}>
          <Text style={styles.buttonText}>Şantiyeye dön</Text>
        </Pressable>
      </View>
    );
  }

  if (!phoneUnlocked) {
    return (
      <View style={styles.center}>
        <Text style={styles.kicker}>KİLİTLİ</Text>
        <Text style={styles.title}>Maktulün telefonu</Text>
        <Text style={styles.body}>
          {desk ? 'Takvimdeki işaret: 19.03' : '4 haneli şifre. Şantiye ofisindeki takvime bak.'}
        </Text>
        <PinKeypad error={pinError} onSubmit={tryPin} />
      </View>
    );
  }

  const opened = EPISODE.phoneItems.find((item) => item.id === openId);
  if (opened) {
    return (
      <ScrollView contentContainerStyle={styles.note}>
        <Pressable accessibilityLabel="Telefon uygulamalarına dön" onPress={() => setOpenId(null)}>
          <Text style={styles.back}>Geri</Text>
        </Pressable>
        <Text style={styles.title}>{opened.title}</Text>
        <Text style={styles.body}>{opened.body}</Text>
      </ScrollView>
    );
  }

  return (
    <View style={styles.screen}>
      <Text style={styles.title}>Telefon açık</Text>
      {EPISODE.phoneItems.map((item) => (
        <Pressable
          key={item.id}
          accessibilityLabel={item.title}
          onPress={() => {
            openPhoneItem(item.id);
            setOpenId(item.id);
          }}
          style={styles.app}
        >
          <Text style={styles.appTitle}>{item.title}</Text>
          <Text style={styles.meta}>{ids.includes(item.unlocksClueId) ? 'Dosyada' : 'Aç'}</Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, padding: 18, gap: 10, justifyContent: 'center' },
  screen: { flex: 1, padding: 16, gap: 10 },
  note: { padding: 16, gap: 10 },
  kicker: { color: colors.danger, letterSpacing: 2 },
  title: { color: colors.ink, fontFamily: fontDisplay, fontSize: 26 },
  body: { color: colors.ink, fontSize: 15, lineHeight: 22 },
  button: { backgroundColor: colors.lamp, padding: 12, alignItems: 'center' },
  buttonText: { color: colors.paperInk, fontWeight: '700' },
  back: { color: colors.lamp },
  app: {
    backgroundColor: colors.nightRaised,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.line,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  appTitle: { color: colors.ink, fontSize: 16 },
  meta: { color: colors.muted },
});
