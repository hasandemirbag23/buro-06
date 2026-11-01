extends RefCounted

## Ortak durum tanımı ve izinli geçişler.

enum State { IDLE, WALKING, RUNNING, TALKING, LISTENING, INVESTIGATING, SITTING, STANDING, REACTING }

## Her durumdan hangi duruma geçilebilir. REACTING her yerden girilebilir ve `end_reaction` ile döner.
const NEXT := {
	State.IDLE: [State.WALKING, State.RUNNING, State.TALKING, State.LISTENING, State.INVESTIGATING, State.SITTING, State.STANDING, State.REACTING],
	State.STANDING: [State.IDLE, State.WALKING, State.RUNNING, State.TALKING, State.LISTENING, State.INVESTIGATING, State.SITTING, State.REACTING],
	State.WALKING: [State.IDLE, State.STANDING, State.RUNNING, State.REACTING],
	State.RUNNING: [State.IDLE, State.STANDING, State.WALKING, State.REACTING],
	State.TALKING: [State.IDLE, State.STANDING, State.LISTENING, State.SITTING, State.INVESTIGATING, State.REACTING],
	State.LISTENING: [State.IDLE, State.STANDING, State.TALKING, State.SITTING, State.INVESTIGATING, State.REACTING],
	State.INVESTIGATING: [State.IDLE, State.STANDING, State.TALKING, State.LISTENING, State.WALKING, State.SITTING, State.REACTING],
	State.SITTING: [State.STANDING, State.TALKING, State.LISTENING, State.INVESTIGATING, State.REACTING],
	State.REACTING: [State.IDLE, State.STANDING, State.SITTING, State.TALKING, State.LISTENING, State.INVESTIGATING, State.WALKING],
}

const STAND_PREREQ := [State.WALKING, State.RUNNING]


static func name_of(state: int) -> String:
	return State.keys()[state]


static func allowed(from: int, to: int) -> bool:
	return from == to or NEXT[from].has(to)
