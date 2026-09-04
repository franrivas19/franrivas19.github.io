/**
 * Tests de las reglas de seguridad de Firestore (firestore.rules) contra el
 * emulador local. No tocan el proyecto real ni requieren estar logueado.
 *
 * Uso:
 *   cd firestore-tests
 *   npm install
 *   npm test
 *
 * Requiere: Node.js, Java (para el emulador de Firestore) y firebase-tools
 * (`npm install -g firebase-tools` o usar `npx firebase-tools`).
 */
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const {
  doc, setDoc, updateDoc, writeBatch, arrayUnion,
} = require('firebase/firestore');

let pass = 0;
let fail = 0;

async function check(name, fn) {
  try {
    await fn();
    pass += 1;
    console.log(`OK   - ${name}`);
  } catch (e) {
    fail += 1;
    console.log(`FAIL - ${name}`);
    console.log(`       ${e.message.split('\n')[0]}`);
  }
}

async function main() {
  const rulesPath = path.join(__dirname, '..', 'firestore.rules');
  const testEnv = await initializeTestEnvironment({
    projectId: 'scarpa-rules-test',
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });

  const base = {
    rol: 'jugador', pj: 0, goles: 0, asistencias: 0,
    puntosDefensivos: 0, totalEstrellas: 0, votosRecibidos: 0, valoracion: 0,
  };

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'usuarios/admin1'), { ...base, rol: 'admin' });
    await setDoc(doc(db, 'usuarios/p1'), { ...base, nombre: 'P1' });
    await setDoc(doc(db, 'usuarios/p2'), { ...base, nombre: 'P2' });
    await setDoc(doc(db, 'usuarios/p3'), { ...base, nombre: 'P3' });
    await setDoc(doc(db, 'usuarios/manager'), { ...base, nombre: 'Manager' });
    await setDoc(doc(db, 'usuarios/j1'), base);
    await setDoc(doc(db, 'usuarios/j2'), base);
    await setDoc(doc(db, 'usuarios/j3'), base);
    await setDoc(doc(db, 'partidos/m1'), { adminPartido: 'p1', estado: 'En Juego', hanVotado: [] });
    await setDoc(doc(db, 'partidos/m2'), { adminPartido: 'manager', estado: 'En Juego', hanVotado: [], estadisticasJugadores: [] });
  });

  const adminCtx = testEnv.authenticatedContext('admin1');
  const p1Ctx = testEnv.authenticatedContext('p1');
  const p3Ctx = testEnv.authenticatedContext('p3');
  const managerCtx = testEnv.authenticatedContext('manager');
  const j1Ctx = testEnv.authenticatedContext('j1');

  // --- Creación de partidos: solo admins ---
  await check('un jugador normal NO puede crear un partido', async () => {
    await assertFails(setDoc(doc(p1Ctx.firestore(), 'partidos/fake1'), { adminPartido: 'p1', estado: 'Pendiente', hanVotado: [] }));
  });
  await check('un admin global SI puede crear un partido', async () => {
    await assertSucceeds(setDoc(doc(adminCtx.firestore(), 'partidos/m3'), { adminPartido: 'admin1', estado: 'Pendiente', hanVotado: [] }));
  });

  // --- Cierre de acta por un admin de partido que no es admin global ---
  await check('el admin de un partido (no admin global) SI puede sumar stats a un companero dentro de limites', async () => {
    await assertSucceeds(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p2'), { goles: 3, pj: 1 }));
  });
  await check('NO puede escalar el rol de un companero', async () => {
    await assertFails(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p2'), { rol: 'admin' }));
  });
  await check('NO puede inflar goles de un companero mas alla del limite por escritura', async () => {
    await assertFails(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p2'), { goles: 999 }));
  });
  await check('NO puede restar (sabotear) stats de un companero', async () => {
    await assertFails(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p2'), { goles: 0 }));
  });
  await check('SI puede sumar un numero grande y realista de puntos defensivos (partido con muchos turnos)', async () => {
    await assertSucceeds(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p2'), { puntosDefensivos: 250 }));
  });
  await check('NO puede sumar una cantidad absurda de puntos defensivos', async () => {
    await assertFails(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p2'), { puntosDefensivos: 100250 }));
  });

  // --- Votaciones ---
  await check('cualquier jugador SI puede sumar una nota a un companero (simula un voto)', async () => {
    await assertSucceeds(updateDoc(doc(p3Ctx.firestore(), 'usuarios/p2'), { totalEstrellas: 4, votosRecibidos: 1 }));
  });
  await check('SI puede marcar su propio voto en hanVotado', async () => {
    await assertSucceeds(updateDoc(doc(p3Ctx.firestore(), 'partidos/m1'), { hanVotado: ['p3'] }));
  });
  await check('NO puede aprovechar la marca de voto para robar el adminPartido', async () => {
    await assertFails(updateDoc(doc(p3Ctx.firestore(), 'partidos/m1'), { adminPartido: 'p3' }));
  });

  // --- Idempotencia del cierre de acta ---
  await check('el admin del partido SI puede cerrar el acta la primera vez', async () => {
    await assertSucceeds(updateDoc(doc(p1Ctx.firestore(), 'partidos/m1'), { estado: 'Finalizado', goles1: 3, goles2: 1 }));
  });
  await check('NO puede volver a cerrarla (ya Finalizado): evita duplicar estadisticas', async () => {
    await assertFails(updateDoc(doc(p1Ctx.firestore(), 'partidos/m1'), { goles1: 30 }));
  });
  await check('un admin global SI puede corregir un partido ya Finalizado', async () => {
    await assertSucceeds(updateDoc(doc(adminCtx.firestore(), 'partidos/m1'), { goles1: 4 }));
  });

  // --- Perfil propio e identidad ---
  await check('cualquiera SI puede editar su propio nombre/foto', async () => {
    await assertSucceeds(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p1'), { nombre: 'Pedro Uno', fotoUrl: 'https://x.png' }));
  });
  await check('nadie puede crear el documento de usuario de otra persona', async () => {
    await assertFails(setDoc(doc(p1Ctx.firestore(), 'usuarios/otraPersona'), { rol: 'jugador' }));
  });
  await check('el doc invitado_global SI se puede crear la primera vez (merge, sin rol)', async () => {
    await assertSucceeds(setDoc(doc(p1Ctx.firestore(), 'usuarios/invitado_global'), { nombre: 'Invitados Globales', pj: 1, goles: 2 }, { merge: true }));
  });
  await check('nadie puede autoascenderse a admin', async () => {
    await assertFails(updateDoc(doc(p1Ctx.firestore(), 'usuarios/p1'), { rol: 'admin' }));
  });

  // --- Igual que el codigo real, pero con WriteBatch (como closeActa/submitRatings) ---
  await check('closeActa real (batch): reparte stats a varios jugadores en un solo batch', async () => {
    const db = managerCtx.firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'partidos/m2'), { estado: 'Finalizado', goles1: 5, goles2: 2 });
    batch.update(doc(db, 'usuarios/manager'), { pj: 1, goles: 2, puntosDefensivos: 4 });
    batch.update(doc(db, 'usuarios/j1'), { pj: 1, asistencias: 2, puntosDefensivos: 6 });
    batch.update(doc(db, 'usuarios/j2'), { pj: 1, asistencias: 1, puntosDefensivos: 8 });
    batch.update(doc(db, 'usuarios/j3'), { pj: 1, goles: 2, puntosDefensivos: 2 });
    await assertSucceeds(batch.commit());
  });
  await check('doble cierre real (batch): se rechaza porque m2 ya esta Finalizado', async () => {
    const db = managerCtx.firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'partidos/m2'), { goles1: 50 });
    batch.update(doc(db, 'usuarios/j1'), { pj: 1 });
    await assertFails(batch.commit());
  });
  await check('submitRatings real (batch): vota a varios companeros y marca hanVotado', async () => {
    const db = j1Ctx.firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'partidos/m2'), { hanVotado: arrayUnion('j1') });
    batch.set(doc(db, 'partidos/m2/votos/j1'), { usuarioId: 'j1', notas: { manager: 4, j2: 5, j3: 3 } });
    batch.set(doc(db, 'usuarios/manager'), { totalEstrellas: 4, votosRecibidos: 1 }, { merge: true });
    batch.set(doc(db, 'usuarios/j2'), { totalEstrellas: 5, votosRecibidos: 1 }, { merge: true });
    batch.set(doc(db, 'usuarios/j3'), { totalEstrellas: 3, votosRecibidos: 1 }, { merge: true });
    await assertSucceeds(batch.commit());
  });
  await check('voto duplicado real (batch): se rechaza el segundo voto al mismo partido', async () => {
    const db = j1Ctx.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'partidos/m2/votos/j1'), { usuarioId: 'j1', notas: { manager: 1 } });
    await assertFails(batch.commit());
  });

  console.log(`\n${pass} pasaron, ${fail} fallaron`);
  await testEnv.cleanup();
  process.exit(fail > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
