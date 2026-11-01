import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { EPISODE } from '../../scenarios/episode_01';
import { colors, fontDisplay } from '../../theme/colors';

export function BuroChatApp() {
  const ids = useGameStore((state) => state.unlockedClueIds);
  const messages = EPISODE.chat.filter((message) => !message.requiresClueId || ids.includes(message.requiresClueId));
  return (
    <ScrollView contentContainerStyle={styles.list}>
      <Text style={styles.head}>BüroChat</Text>
      {messages.map((message) => (
        <View key={message.id} style={styles.bubble}>
          <View style={styles.row}>
            <Text style={styles.sender}>{message.sender}</Text>
            <Text style={styles.time}>{message.at}</Text>
          </View>
          <Text style={styles.text}>{message.text}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  list: { padding: 14, gap: 10 },
  head: { color: colors.ink, fontFamily: fontDisplay, fontSize: 24 },
  bubble: { backgroundColor: colors.nightRaised, padding: 12, gap: 4, borderLeftWidth: 3, borderLeftColor: colors.lamp },
  row: { flexDirection: 'row', justifyContent: 'space-between' },
  sender: { color: colors.lamp, fontSize: 13 },
  time: { color: colors.muted, fontSize: 12 },
  text: { color: colors.ink, fontSize: 15, lineHeight: 21 },
});
