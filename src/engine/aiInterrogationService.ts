import { suspectById } from '../scenarios/episode_01';
import type { CharacterAnimState, SuspectId } from './types';

const BASE_BPM = 75;
const MAX_BPM = 160;

export function bpmForStress(stress: number): number {
  const clamped = Math.max(0, Math.min(100, stress));
  return Math.round(BASE_BPM + (clamped / 100) * (MAX_BPM - BASE_BPM));
}

export function animForStress(
  id: SuspectId,
  stress: number,
  confessed: boolean,
): CharacterAnimState {
  if (confessed || stress >= 100) return 'BROKEN_CONFESS';
  if (stress >= 35) return 'NERVOUS_SWEAT';
  return id === 'tarik' ? 'ARROGANT' : 'IDLE';
}

export interface SlamInput {
  suspectId: SuspectId;
  clueId: string;
  stress: number;
  alreadyUsed: boolean;
}

export interface SlamResult {
  accepted: boolean;
  stress: number;
  bpm: number;
  anim: CharacterAnimState;
  confessed: boolean;
  line: string;
  cevdetLine: string;
}

export function resolveSlam(input: SlamInput): SlamResult {
  const suspect = suspectById(input.suspectId);
  const accepted = !input.alreadyUsed && suspect.acceptedClueIds.includes(input.clueId);
  const delta = accepted ? 35 : input.alreadyUsed ? 0 : 10;
  const stress = Math.min(100, input.stress + delta);
  const confessed = stress >= 100;
  const anim = confessed
    ? 'BROKEN_CONFESS'
    : accepted
      ? 'ANGRY_SLAM'
      : animForStress(input.suspectId, stress, false);
  const line = input.alreadyUsed
    ? 'Bunu zaten gördüm. Yeni bir şey koy masaya.'
    : confessed
      ? suspect.lines.confess
      : accepted
        ? suspect.lines.hit
        : suspect.lines.miss;
  const cevdetLine = confessed
    ? 'İşte bu. Tutanağa geç.'
    : accepted
      ? 'Sıkıştır. Elini masadan çekmesin.'
      : 'La bebe, yanlış dosya!';
  return {
    accepted,
    stress,
    bpm: bpmForStress(stress),
    anim,
    confessed,
    line,
    cevdetLine,
  };
}
