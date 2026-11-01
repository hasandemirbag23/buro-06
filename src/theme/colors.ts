import { Platform } from 'react-native';

export const colors = {
  night: '#0c1016',
  nightRaised: '#161c27',
  ink: '#e7e1d6',
  muted: '#9a9184',
  lamp: '#e6b450',
  lampDim: '#8a6a32',
  policeRed: '#c23b3b',
  policeBlue: '#2f5fbf',
  tea: '#6b3a2a',
  paper: '#d8c7a1',
  paperInk: '#2a2118',
  crt: '#9dff8a',
  crtDim: '#12301c',
  cork: '#6b4428',
  danger: '#e15b5b',
  ok: '#7dcea0',
  metal: '#8d97a5',
  mud: '#2a241c',
  caution: '#e2c044',
  bezel: '#07080c',
  line: '#2a3140',
  skin: '#d7b599',
};

export const fontDisplay =
  Platform.select({
    web: 'Georgia, "Times New Roman", serif',
    ios: 'Georgia',
    default: 'serif',
  }) ?? 'serif';
