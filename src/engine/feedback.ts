import { Platform } from 'react-native';
import * as Haptics from 'expo-haptics';

export function buzz(kind: 'slam' | 'clue' | 'err') {
  if (Platform.OS === 'web') return;
  const run =
    kind === 'slam'
      ? Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy)
      : kind === 'clue'
        ? Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success)
        : Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
  void run.catch(() => undefined);
}
