import { Pressable, StyleSheet, Text, View } from 'react-native';
import { BuroChatApp } from '../../apps/BuroChat/BuroChatApp';
import { ESorguApp } from '../../apps/ESorgu/ESorguApp';
import { EvidenceBoardApp } from '../../apps/EvidenceBoard/EvidenceBoardApp';
import { HomeScreen } from '../../apps/HomeScreen/HomeScreen';
import { VictimPhoneApp } from '../../apps/VictimPhone/VictimPhoneApp';
import { useGameStore } from '../../engine/useGameStore';
import { colors } from '../../theme/colors';

export function TabletShell() {
  const tabletApp = useGameStore((state) => state.tabletApp);
  const openTablet = useGameStore((state) => state.openTablet);
  return (
    <View style={styles.shell}>
      {tabletApp !== 'home' ? (
        <Pressable accessibilityLabel="Tablette ana ekran" onPress={() => openTablet('home')} style={styles.back}>
          <Text style={styles.backText}>Ana ekran</Text>
        </Pressable>
      ) : null}
      <View style={styles.body}>
        {tabletApp === 'home' ? <HomeScreen /> : null}
        {tabletApp === 'chat' ? <BuroChatApp /> : null}
        {tabletApp === 'phone' ? <VictimPhoneApp /> : null}
        {tabletApp === 'esorgu' ? <ESorguApp /> : null}
        {tabletApp === 'board' ? <EvidenceBoardApp /> : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  shell: { flex: 1, backgroundColor: colors.night },
  back: { paddingHorizontal: 14, paddingTop: 8 },
  backText: { color: colors.lamp },
  body: { flex: 1 },
});
