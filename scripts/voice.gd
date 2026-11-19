extends CanvasLayer
## Obrolan suara co-op (web saja). Suara memakai RTCPeerConnection milik browser (Opus, peredam
## gema), terpisah dari WebRTC data game; tukar SDP/ICE-nya menumpang RPC game yang sudah tersambung.
## Mik mati sampai pemain menekan ikon mik di kanan atas (atau tombol V); suara teman selalu terdengar.

const ICON_ON := preload("res://assets/ui/mic_on.svg")
const ICON_OFF := preload("res://assets/ui/mic_off.svg")

const JS := """
window.lnVoice = (() => {
  const v = {pcs: {}, pending: {}, mic: null, on: false, send: null, onstate: null};
  const ICE = {iceServers: [{urls: ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']}]};
  const track = () => v.mic ? v.mic.getAudioTracks()[0] : null;
  const attach = (pc) => {
    const t = pc.getTransceivers()[0];
    if (!t) return;
    t.direction = 'sendrecv';
    if (track()) t.sender.replaceTrack(track());
  };
  v.peer = (id, offerer) => {
    const pc = new RTCPeerConnection(ICE);
    v.pcs[id] = pc;
    v.pending[id] = [];
    pc.onicecandidate = (e) => { if (e.candidate) v.send(id, JSON.stringify({ice: e.candidate})); };
    pc.ontrack = (e) => {
      const a = new Audio();
      a.srcObject = e.streams[0] || new MediaStream([e.track]);
      a.play().catch(() => {});
      pc.audio = a;
    };
    if (offerer) {
      pc.addTransceiver('audio', {direction: 'sendrecv'});
      attach(pc);
      pc.createOffer().then((o) => pc.setLocalDescription(o))
        .then(() => v.send(id, JSON.stringify({sdp: pc.localDescription})));
    }
    return pc;
  };
  v.recv = async (id, json) => {
    const m = JSON.parse(json);
    const pc = v.pcs[id] || v.peer(id, false);
    if (m.sdp) {
      await pc.setRemoteDescription(m.sdp);
      if (m.sdp.type === 'offer') {
        attach(pc);
        await pc.setLocalDescription(await pc.createAnswer());
        v.send(id, JSON.stringify({sdp: pc.localDescription}));
      }
      for (const c of v.pending[id]) pc.addIceCandidate(c).catch(() => {});
      v.pending[id] = [];
    } else if (m.ice) {
      if (pc.remoteDescription) pc.addIceCandidate(m.ice).catch(() => {});
      else v.pending[id].push(m.ice);
    }
  };
  v.setMic = async (on) => {
    try {
      if (on && !v.mic) {
        v.mic = await navigator.mediaDevices.getUserMedia({audio: {echoCancellation: true, noiseSuppression: true, autoGainControl: true}});
        for (const pc of Object.values(v.pcs)) attach(pc);
      }
      if (track()) track().enabled = on;
      v.on = on;
      v.onstate(on ? 'on' : 'off');
    } catch (e) {
      v.onstate('denied');
    }
  };
  v.drop = (id) => {
    const pc = v.pcs[id];
    if (pc) { pc.close(); if (pc.audio) pc.audio.srcObject = null; }
    delete v.pcs[id];
  };
  v.stop = () => {
    for (const id of Object.keys(v.pcs)) v.drop(id);
    if (v.mic) v.mic.getTracks().forEach((t) => t.stop());
    v.mic = null;
  };
  return v;
})();
"""

var _js: JavaScriptObject
var _callbacks := []  # referensi callback JS harus disimpan supaya tidak dibuang
var _button: Button
var _on := false


func _ready() -> void:
	if not OS.has_feature("web") or not Net.online:
		queue_free()
		return
	layer = 1  # sama dengan HUD; Pasar (layer 2) menutupinya, chat ada di sana
	JavaScriptBridge.eval(JS, true)
	_js = JavaScriptBridge.get_interface("lnVoice")
	_callbacks = [JavaScriptBridge.create_callback(_on_js_send), JavaScriptBridge.create_callback(_on_js_state)]
	_js.send = _callbacks[0]
	_js.onstate = _callbacks[1]
	multiplayer.peer_disconnected.connect(func(id): _js.drop(id))
	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	_button.flat = true
	_button.expand_icon = true
	_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_button.offset_left = -24
	_button.offset_top = 4
	_button.offset_right = -6
	_button.offset_bottom = 22
	_button.tooltip_text = "Mikrofon: klik atau tombol V untuk nyala/mati"
	_button.pressed.connect(toggle)
	add_child(_button)
	_update_button("off")


## Dipanggil main di awal wave 1 (semua peer sudah memuat game): id kecil menawarkan ke id besar.
func connect_peers() -> void:
	var me := multiplayer.get_unique_id()
	for id in Net.players:
		if id > me:
			_js.peer(id, true)


func toggle() -> void:
	_js.setMic(not _on)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		toggle()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if _js:
		_js.stop()


func _on_js_send(args: Array) -> void:
	_signal.rpc_id(int(args[0]), str(args[1]))


func _on_js_state(args: Array) -> void:
	_update_button(str(args[0]))


@rpc("any_peer", "reliable")
func _signal(json: String) -> void:
	_js.recv(multiplayer.get_remote_sender_id(), json)


func _update_button(state: String) -> void:
	_on = state == "on"
	_button.icon = ICON_ON if _on else ICON_OFF
	_button.modulate = Color(1, 0.5, 0.5) if state == "denied" else Color.WHITE
	if state == "denied":
		_button.tooltip_text = "Izin mikrofon ditolak browser"
