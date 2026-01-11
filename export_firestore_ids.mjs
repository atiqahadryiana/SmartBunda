import fs from 'node:fs/promises';

import { initializeApp } from 'firebase/app';
import { collection, getDocs, getFirestore } from 'firebase/firestore';

const FIREBASE_OPTIONS_PATH = 'lib/firebase_options.dart';
const FIRESTORE_PATHS_PATH = 'lib/firestore_paths.dart';
const OUTPUT_PATH = 'firestore-ids.json';

const FIREBASE_KEYS = [
  'apiKey',
  'authDomain',
  'projectId',
  'storageBucket',
  'messagingSenderId',
  'appId',
];

async function loadFirebaseConfig() {
  const raw = await fs.readFile(FIREBASE_OPTIONS_PATH, 'utf8');
  const config = {};
  for (const key of FIREBASE_KEYS) {
    const match = raw.match(new RegExp(`${key}:\\s*'([^']+)'`));
    if (!match) {
      throw new Error(`Missing ${key} in ${FIREBASE_OPTIONS_PATH}`);
    }
    config[key] = match[1];
  }
  return config;
}

async function loadCollectionNames() {
  const raw = await fs.readFile(FIRESTORE_PATHS_PATH, 'utf8');
  const regex = /static const \w+\s*=\s*"([^"]+)"/g;
  const names = new Set();
  let match;
  while ((match = regex.exec(raw)) !== null) {
    names.add(match[1]);
  }
  names.delete('global');
  return Array.from(names).sort();
}

async function listDocs(db, path) {
  const snapshot = await getDocs(collection(db, path));
  return snapshot.docs.map((doc) => doc.id);
}

async function main() {
  const config = await loadFirebaseConfig();
  const app = initializeApp(config);
  const db = getFirestore(app);
  const collectionNames = await loadCollectionNames();

  const result = {
    generatedAt: new Date().toISOString(),
    projectId: config.projectId,
    collections: {},
  };

  for (const name of collectionNames) {
    try {
      const docIds = await listDocs(db, name);
      const entry = { docIds, count: docIds.length };
      if (name === 'FoodLogs') {
        const subcollections = {};
        for (const userId of docIds) {
          try {
            const dayIds = await listDocs(db, `${name}/${userId}/Days`);
            const entriesByDay = {};
            for (const dayId of dayIds) {
              try {
                const entryIds = await listDocs(
                  db,
                  `${name}/${userId}/Days/${dayId}/Entries`,
                );
                entriesByDay[dayId] = {
                  docIds: entryIds,
                  count: entryIds.length,
                };
              } catch (err) {
                entriesByDay[dayId] = { error: err.message };
              }
            }
            subcollections[userId] = {
              Days: { docIds: dayIds, count: dayIds.length, Entries: entriesByDay },
            };
          } catch (err) {
            subcollections[userId] = { error: err.message };
          }
        }
        entry.subcollections = subcollections;
      }
      result.collections[name] = entry;
    } catch (err) {
      result.collections[name] = { error: err.message };
    }
  }

  await fs.writeFile(OUTPUT_PATH, JSON.stringify(result, null, 2));
  const summary = Object.entries(result.collections).map(([name, data]) => {
    if (data.error) return `${name}: error (${data.error})`;
    return `${name}: ${data.count} docs`;
  });
  await fs.writeFile('firestore-ids-summary.txt', summary.join('\n') + '\n');
  console.log(`Wrote ${OUTPUT_PATH} and firestore-ids-summary.txt`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
