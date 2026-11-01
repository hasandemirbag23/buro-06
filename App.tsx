import { StatusBar } from 'expo-status-bar';
import { StyleSheet, useWindowDimensions, View } from 'react-native';
import { InterrogationApp } from './src/apps/Interrogation/InterrogationApp';
import { BottomNavigation } from './src/components/os/BottomNavigation';
import { IncomingCallModal } from './src/components/os/IncomingCallModal';
import { NotificationBanner } from './src/components/os/NotificationBanner';
import { SceneHeader } from './src/components/os/SceneHeader';
import { TabletShell } from './src/components/os/TabletShell';
import { TopStatusBar } from './src/components/os/TopStatusBar';
import { CaseClosedReport } from './src/components/shared/CaseClosedReport';
import { ClueUnlockedModal } from './src/components/shared/ClueUnlockedModal';
import { useGameStore } from './src/engine/useGameStore';
import { CrimeSceneView } from './src/scenes3d/CrimeSceneView';
import { Interrogation3DStage } from './src/scenes3d/Interrogation3DStage';
import { OfficeSceneView } from './src/scenes3d/OfficeSceneView';
import { colors } from './src/theme/colors';

export default function App() {
  const { width, height } = useWindowDimensions();
  const layer = useGameStore((state) => state.layer);
  const scene = useGameStore((state) => state.scene);
  const frameW = Math.min(width, 430);
  const frameH = Math.min(height, 900);

  return (
    <View style={styles.root}>
      <StatusBar style="light" />
      <View style={[styles.frame, { width: frameW, height: frameH }]}>
        {layer === 'tablet' ? (
          <>
            <TopStatusBar />
            <TabletShell />
          </>
        ) : (
          <>
            <SceneHeader />
            <View style={scene === 'interrogation' ? styles.stageSplit : styles.stageFull}>
              {scene === 'office' ? <OfficeSceneView /> : null}
              {scene === 'site' ? <CrimeSceneView /> : null}
              {scene === 'interrogation' ? <Interrogation3DStage /> : null}
            </View>
            {scene === 'interrogation' ? (
              <View style={styles.interrogation}>
                <InterrogationApp />
              </View>
            ) : null}
          </>
        )}
        <NotificationBanner />
        <BottomNavigation />
        <IncomingCallModal />
        <ClueUnlockedModal />
        <CaseClosedReport />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.bezel,
    alignItems: 'center',
    justifyContent: 'center',
  },
  frame: { backgroundColor: colors.night, overflow: 'hidden', position: 'relative' },
  stageFull: { flex: 1 },
  stageSplit: { flex: 0.62 },
  interrogation: { flex: 0.38 },
});
