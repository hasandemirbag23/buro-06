import { create } from 'zustand';
import {
  arrestUnlocked,
  clueById,
  EPISODE,
  normalizeQuery,
  suspectById,
} from '../scenarios/episode_01';
import { animForStress, resolveSlam } from './aiInterrogationService';
import { buzz } from './feedback';
import type {
  CameraFrame,
  ClueDef,
  DialogueLine,
  EsorguHit,
  IncomingCall,
  LayerId,
  SceneId,
  SuspectId,
  TabletAppId,
  CharacterAnimState,
} from './types';

interface GameData {
  scene: SceneId;
  layer: LayerId;
  tabletApp: TabletAppId;
  unlockedClueIds: string[];
  inspectedHotspotIds: string[];
  phoneUnlocked: boolean;
  pinError: boolean;
  activeSuspect: SuspectId | null;
  stress: Record<SuspectId, number>;
  anim: Record<SuspectId, CharacterAnimState>;
  bpm: Record<SuspectId, number>;
  confessed: Record<SuspectId, boolean>;
  usedBySuspect: Record<SuspectId, string[]>;
  camera: CameraFrame;
  slamClueId: string | null;
  tableClueIds: string[];
  impactNonce: number;
  dialogue: DialogueLine | null;
  cevdetLine: string | null;
  cevdetAnim: CharacterAnimState;
  clueModal: ClueDef | null;
  notification: string | null;
  incomingCall: IncomingCall | null;
  esorguHistory: EsorguHit[];
  briefingDone: boolean;
  showCaseReport: boolean;
}

interface GameActions {
  setLayer: (layer: LayerId) => void;
  openTablet: (app?: TabletAppId) => void;
  dismissNotification: () => void;
  dismissClue: () => void;
  answerCall: () => void;
  declineCall: () => void;
  travel: (scene: SceneId) => void;
  brief: () => void;
  inspectHotspot: (id: string) => void;
  tryPin: (pin: string) => boolean;
  clearPinError: () => void;
  openPhoneItem: (itemId: string) => void;
  searchEsorgu: (raw: string) => void;
  selectSuspect: (id: SuspectId) => void;
  setCamera: (camera: CameraFrame) => void;
  slamEvidence: (clueId: string) => void;
  closeCaseReport: () => void;
  openCaseReport: () => void;
  resetCase: () => void;
}

export type GameStore = GameData & GameActions;

function fresh(): GameData {
  return {
    scene: 'office',
    layer: 'world',
    tabletApp: 'home',
    unlockedClueIds: [],
    inspectedHotspotIds: [],
    phoneUnlocked: false,
    pinError: false,
    activeSuspect: null,
    stress: { zafer: 0, tarik: 0 },
    anim: { zafer: 'IDLE', tarik: 'ARROGANT' },
    bpm: { zafer: 75, tarik: 75 },
    confessed: { zafer: false, tarik: false },
    usedBySuspect: { zafer: [], tarik: [] },
    camera: 'wide',
    slamClueId: null,
    tableClueIds: [],
    impactNonce: 0,
    dialogue: null,
    cevdetLine: null,
    cevdetAnim: 'IDLE',
    clueModal: null,
    notification: null,
    incomingCall: {
      from: 'Başkomiser Cevdet',
      text: 'Ofise gel. Vadi Kule dosyası masanda, çay demlendi.',
    },
    esorguHistory: [],
    briefingDone: false,
    showCaseReport: false,
  };
}

function unlock(ids: string[], clueId: string): string[] {
  return ids.includes(clueId) ? ids : [...ids, clueId];
}

export const useGameStore = create<GameStore>((set, get) => ({
  ...fresh(),
  setLayer: (layer) => set({ layer }),
  openTablet: (app = 'home') => set({ layer: 'tablet', tabletApp: app }),
  dismissNotification: () => set({ notification: null }),
  dismissClue: () => set({ clueModal: null }),
  answerCall: () =>
    set({
      incomingCall: null,
      notification: 'Brifing Cevdet’in masasında.',
      scene: 'office',
      layer: 'world',
    }),
  declineCall: () =>
    set({
      incomingCall: null,
      notification: 'Cevdet ofiste. Masasına uğra.',
    }),
  travel: (scene) => {
    if (scene === 'interrogation' && !arrestUnlocked(get().unlockedClueIds)) {
      set({
        notification: 'Gözaltı için Zafer SMS’i, şirket kaydı veya PTS lazım.',
      });
      return;
    }
    set({
      scene,
      layer: 'world',
      dialogue: null,
      cevdetLine: null,
      cevdetAnim: 'IDLE',
    });
  },
  brief: () =>
    set({
      briefingDone: true,
      cevdetAnim: 'TALKING',
      dialogue: { speaker: 'Başkomiser Cevdet', text: EPISODE.briefing },
    }),
  inspectHotspot: (id) => {
    const spot = EPISODE.hotspots.find((item) => item.id === id);
    if (!spot) return;
    const snap = get();
    const clue = clueById(spot.unlocksClueId);
    const known = snap.unlockedClueIds.includes(spot.unlocksClueId);
    set({
      dialogue: spot.inspectorDialogue,
      inspectedHotspotIds: snap.inspectedHotspotIds.includes(id)
        ? snap.inspectedHotspotIds
        : [...snap.inspectedHotspotIds, id],
      unlockedClueIds: known
        ? snap.unlockedClueIds
        : unlock(snap.unlockedClueIds, spot.unlocksClueId),
      clueModal: known || !clue ? null : clue,
      notification: known || !clue ? null : `${clue.title} envantere girdi.`,
    });
    if (!known) buzz('clue');
  },
  tryPin: (pin) => {
    if (pin === EPISODE.pin) {
      set({ phoneUnlocked: true, pinError: false, notification: 'Telefon kilidi açıldı.' });
      buzz('clue');
      return true;
    }
    set({ pinError: true, notification: 'Hatalı şifre.' });
    buzz('err');
    return false;
  },
  clearPinError: () => set({ pinError: false }),
  openPhoneItem: (itemId) => {
    const item = EPISODE.phoneItems.find((entry) => entry.id === itemId);
    const snap = get();
    if (!item || !snap.phoneUnlocked) return;
    const clue = clueById(item.unlocksClueId);
    const known = snap.unlockedClueIds.includes(item.unlocksClueId);
    if (!known && clue) {
      set({
        unlockedClueIds: unlock(snap.unlockedClueIds, item.unlocksClueId),
        clueModal: clue,
        notification: `${clue.title} envantere girdi.`,
      });
      buzz('clue');
    }
  },
  searchEsorgu: (raw) => {
    const key = normalizeQuery(raw);
    if (!key) {
      set({ notification: 'Sorgu metni boş.' });
      return;
    }
    const snap = get();
    const record = EPISODE.esorgu.find((entry) => entry.keys.includes(key));
    if (!record) {
      set({
        esorguHistory: [
          {
            query: raw.trim(),
            found: false,
            title: 'Kayıt yok',
            body: 'GBT, PTS ve HTS kayıtlarında eşleşme yok.',
          },
          ...snap.esorguHistory,
        ].slice(0, 8),
      });
      buzz('err');
      return;
    }
    const clue = clueById(record.unlocksClueId);
    const known = snap.unlockedClueIds.includes(record.unlocksClueId);
    set({
      esorguHistory: [
        { query: raw.trim(), found: true, title: record.title, body: record.body },
        ...snap.esorguHistory,
      ].slice(0, 8),
      unlockedClueIds:
        known || !clue ? snap.unlockedClueIds : unlock(snap.unlockedClueIds, record.unlocksClueId),
      clueModal: known || !clue ? null : clue,
      notification: known || !clue ? null : `${clue.title} envantere girdi.`,
    });
    if (!known) buzz('clue');
  },
  selectSuspect: (id) => {
    const suspect = suspectById(id);
    set({
      activeSuspect: id,
      camera: 'wide',
      dialogue: { speaker: suspect.character.name, text: suspect.lines.idle },
      cevdetLine: null,
      cevdetAnim: 'IDLE',
      slamClueId: null,
    });
  },
  setCamera: (camera) => set({ camera }),
  slamEvidence: (clueId) => {
    const snap = get();
    const suspectId = snap.activeSuspect;
    if (!suspectId) {
      set({ notification: 'Önce şüpheliyi sandalyeye oturt.' });
      return;
    }
    if (!snap.unlockedClueIds.includes(clueId)) return;
    const result = resolveSlam({
      suspectId,
      clueId,
      stress: snap.stress[suspectId],
      alreadyUsed: snap.usedBySuspect[suspectId].includes(clueId),
    });
    const confessed = { ...snap.confessed, [suspectId]: result.confessed };
    const nonce = snap.impactNonce + 1;
    set({
      stress: { ...snap.stress, [suspectId]: result.stress },
      bpm: { ...snap.bpm, [suspectId]: result.bpm },
      anim: { ...snap.anim, [suspectId]: result.anim },
      confessed,
      usedBySuspect: {
        ...snap.usedBySuspect,
        [suspectId]: result.accepted
          ? [...snap.usedBySuspect[suspectId], clueId]
          : snap.usedBySuspect[suspectId],
      },
      dialogue: { speaker: suspectById(suspectId).character.name, text: result.line },
      cevdetLine: result.cevdetLine,
      cevdetAnim: result.accepted ? 'IDLE' : 'TALKING',
      slamClueId: clueId,
      tableClueIds: snap.tableClueIds.includes(clueId)
        ? snap.tableClueIds
        : [...snap.tableClueIds, clueId],
      impactNonce: nonce,
      camera: result.accepted ? 'closeup' : snap.camera,
      showCaseReport: confessed.zafer && confessed.tarik,
      notification: result.accepted ? 'Kanıt masaya indi.' : 'Kanıt tutmadı.',
    });
    buzz(result.accepted ? 'slam' : 'err');
    if (result.anim === 'ANGRY_SLAM') {
      setTimeout(() => {
        const now = get();
        if (now.impactNonce !== nonce) return;
        if (now.anim[suspectId] !== 'ANGRY_SLAM') return;
        set({
          anim: {
            ...now.anim,
            [suspectId]: animForStress(suspectId, now.stress[suspectId], now.confessed[suspectId]),
          },
        });
      }, 720);
    }
  },
  closeCaseReport: () => set({ showCaseReport: false }),
  openCaseReport: () => {
    const snap = get();
    if (snap.confessed.zafer && snap.confessed.tarik) set({ showCaseReport: true });
  },
  resetCase: () => set(fresh()),
}));

export function caseIsClosed(confessed: Record<SuspectId, boolean>): boolean {
  return confessed.zafer && confessed.tarik;
}
