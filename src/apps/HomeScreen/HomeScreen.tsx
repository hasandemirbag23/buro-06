import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { TabletAppId } from '../../engine/types';
import { useGameStore } from '../../engine/useGameStore';
import { arrestUnlocked, phoneReady } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

export function HomeScreen() {
  const openTablet = useGameStore((state) => state.openTablet);
  const travel = useGameStore((state) => state.travel);
  const ids = useGameStore((state) => state.unlockedClueIds);
  const phone = phoneReady(ids);
  const arrest = arrestUnlocked(ids);

  const apps: { id: TabletAppId | 'go-interrogation'; title: string; icon: string; locked: boolean }[] = [
    { id: 'chat', title: 'BüroChat', icon: '💬', locked: false },
    { id: 'phone', title: 'Maktulün Telefonu', icon: '📱', locked: !phone },
    { id: 'esorgu', title: 'E-Sorgu', icon: '🔎', locked: false },
    { id: 'board', title: 'Kanıt Panosu', icon: '📌', locked: false },
    { id: 'go-interrogation', title: 'Sorgu', icon: '🎙️', locked: !arrest },
  ];

  function open(id: TabletAppId | 'go-interrogation') {
    if (id === 'go-interrogation') {
      travel('interrogation');
      return;
    }
    if (id === 'phone' && !phone) {
      useGameStore.setState({
        notification: 'Telefon olay yerinde. Cesedin yanındaki cihaz poşete girmeden açılmaz.',
      });
      return;
    }
    openTablet(id);
  }

  return (
    <View style={styles.screen}>
      <Text style={styles.kicker}>GÖREV TABLETİ</Text>
      <Text style={styles.title}>Vadi Kule</Text>
      <View style={styles.grid}>
        {apps.map((app) => (
          <Pressable
            key={app.id}
            accessibilityLabel={app.title}
            onPress={() => open(app.id)}
            style={[styles.tile, app.locked && styles.locked]}
          >
            <Text style={styles.icon}>{app.icon}</Text>
            <Text style={styles.name}>{app.title}</Text>
            {app.locked ? <Text style={styles.lock}>Kilitli</Text> : null}
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 16, gap: 8 },
  kicker: { color: colors.muted, letterSpacing: 2, fontSize: 11 },
  title: { color: colors.ink, fontFamily: fontDisplay, fontSize: 28 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginTop: 8 },
  tile: {
    width: '47%',
    backgroundColor: colors.nightRaised,
    padding: 14,
    gap: 6,
    borderWidth: 1,
    borderColor: colors.line,
    minHeight: 110,
  },
  locked: { opacity: 0.55 },
  icon: { fontSize: 26 },
  name: { color: colors.ink, fontSize: 15 },
  lock: { color: colors.danger, fontSize: 12 },
});
