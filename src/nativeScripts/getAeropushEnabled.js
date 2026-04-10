try {
  // const aeropushConfig = require('../../example/aeropush.config.js'); // testing import
  const aeropushConfig = require('../../../../aeropush.config.js'); // prod import
  console.log(aeropushConfig?.aeropushEnabled);
} catch {
  console.log(true);
}
