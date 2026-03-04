const pollIntervalMs = Number(process.env.POLL_INTERVAL_MS || 5000);
const consumerGroup = process.env.EVENTHUB_CONSUMER_GROUP || 'processor';

console.log('msk-tail-processor worker starting');
console.log(`consumer group: ${consumerGroup}`);
console.log(`poll interval: ${pollIntervalMs}ms`);

setInterval(() => {
  const now = new Date().toISOString();
  console.log(`[${now}] tail tick: waiting for Event Hubs messages`);
}, pollIntervalMs);
