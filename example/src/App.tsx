import { Text, View, StyleSheet, Button } from 'react-native';
import {
  withAeropush,
  useAeropushUpdate,
  useAeropushModal,
  sync,
  restart,
} from 'react-native-aeropush';

function AppContent() {
  const { isRestartRequired, currentlyRunningBundle, newReleaseBundle } =
    useAeropushUpdate();
  const { showModal } = useAeropushModal();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Aeropush Example</Text>

      <Button title="Open Aeropush Modal" onPress={showModal} />

      <Button title="Check for Updates" onPress={sync} />

      {isRestartRequired && (
        <Button title="Restart to Apply Update" onPress={restart} />
      )}

      {currentlyRunningBundle && (
        <Text style={styles.info}>
          Running: v{currentlyRunningBundle.version}
        </Text>
      )}

      {newReleaseBundle && (
        <Text style={styles.info}>
          New release available: v{newReleaseBundle.version}
        </Text>
      )}
    </View>
  );
}

const App = withAeropush(AppContent);
export default App;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  info: {
    marginTop: 10,
    fontSize: 14,
    color: '#666',
  },
});
