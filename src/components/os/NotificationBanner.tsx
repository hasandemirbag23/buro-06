import { useEffect } from 'react';
import { StyleSheet, Text } from 'react-native';
import { useGameStore } from '../../engine/useGameStore';
import { colors } from '../../theme/colors';

export function NotificationBanner() {
  const notification = useGameStore((state) => state.notification);
  const dismissNotification = useGameStore((state) => state.dismissNotification);
  useEffect(() => {
    if (!notification) return;
    const id = setTimeout(() => dismissNotification(), 3200);
    return () => clearTimeout(id);
  }, [dismissNotification, notification]);
  if (!notification) return null;
  return <Text style={styles.banner}>{notification}</Text>;
}

const styles = StyleSheet.create({
  banner: {
    position: 'absolute',
    top: 44,
    left: 12,
    right: 12,
    zIndex: 20,
    backgroundColor: '#241c12',
    color: colors.lamp,
    borderWidth: 1,
    borderColor: colors.lampDim,
    padding: 10,
    overflow: 'hidden',
  },
});
