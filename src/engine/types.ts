export type CharacterAnimState =
  | 'IDLE'
  | 'TALKING'
  | 'ARROGANT'
  | 'NERVOUS_SWEAT'
  | 'ANGRY_SLAM'
  | 'BROKEN_CONFESS';

export type SceneId = 'office' | 'site' | 'interrogation';
export type LayerId = 'world' | 'tablet';
export type TabletAppId = 'home' | 'chat' | 'phone' | 'esorgu' | 'board';
export type SuspectId = 'zafer' | 'tarik';
export type CameraFrame = 'wide' | 'closeup' | 'tabletop';
export type Pose = 'stand' | 'sit' | 'kneel';

export interface SceneHotspot {
  id: string;
  title: string;
  subtitle: string;
  position: { x: number; y: number };
  icon: string;
  requiredClueId?: string;
  unlocksClueId: string;
  inspectorDialogue: {
    speaker: 'Başkomiser Cevdet' | 'Akbaba' | 'Komiser';
    text: string;
  };
}

export interface CharacterModelConfig {
  id: string;
  name: string;
  role: string;
  modelType: 'POLICE' | 'CRIMINAL_BOSS' | 'SITE_CHIEF' | 'FORENSIC';
  primaryColor: string;
  secondaryColor: string;
  accessory: 'TEA_GLASS' | 'CAMERA' | 'HARD_HAT' | 'GOLD_WATCH' | 'BADGE';
  currentAnimState: CharacterAnimState;
  heartRateBpm: number;
}

export interface ClueDef {
  id: string;
  title: string;
  summary: string;
  source: 'scene' | 'phone' | 'esorgu';
  icon: string;
}

export interface ChatMessage {
  id: string;
  sender: 'Cevdet' | 'Akbaba' | 'Hayalet' | 'Komiser';
  text: string;
  at: string;
  requiresClueId?: string;
}

export interface EsorguRecord {
  keys: string[];
  title: string;
  body: string;
  unlocksClueId: string;
}

export interface PhoneItem {
  id: string;
  app: 'bank' | 'notes' | 'sms';
  title: string;
  body: string;
  unlocksClueId: string;
}

export interface SuspectDef {
  id: SuspectId;
  character: CharacterModelConfig;
  acceptedClueIds: string[];
  lines: {
    idle: string;
    hit: string;
    miss: string;
    confess: string;
  };
}

export interface DialogueLine {
  speaker: string;
  text: string;
}

export interface EsorguHit {
  query: string;
  found: boolean;
  title: string;
  body: string;
}

export interface IncomingCall {
  from: string;
  text: string;
}
