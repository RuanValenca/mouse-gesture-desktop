#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
;  mouse-gestures.ahk
;  Gestos globais com o botão direito do mouse
;
;    Botão direito + arrastar para CIMA   -> Ctrl + Home
;    Botão direito + arrastar para BAIXO  -> Ctrl + End
;    Botão direito sem arrastar           -> clique direito normal
;
;  Funciona em qualquer programa do Windows que aceite esses
;  atalhos (navegadores, Explorer, VS Code, Bloco de Notas...).
; ============================================================


; ------------------------------------------------------------
;  CONFIGURAÇÃO
; ------------------------------------------------------------

threshold := 50          ; deslocamento vertical mínimo, em pixels

maxHorizontal := 0       ; 0  = ignora o movimento horizontal
                         ; >0 = só aceita o gesto se o desvio
                         ;      horizontal for menor que esse valor
                         ;      (ex.: 150 para exigir traço reto)

focusUnderMouse := false ; true = ativa a janela sob o cursor antes
                         ;        de enviar o atalho

clickDelay := 10         ; ms entre down/up do clique direito simulado

; Programas onde os gestos ficam desativados (o botão direito
; funciona 100% nativo). Útil para jogos, VMs, acesso remoto.
excludedWindows := [
    "ahk_exe mstsc.exe",
    "ahk_exe VirtualBoxVM.exe",
    "ahk_exe vmware.exe"
]


; ------------------------------------------------------------
;  INICIALIZAÇÃO
; ------------------------------------------------------------

CoordMode "Mouse", "Screen"
InstallMouseHook()          ; hook global, garante captura em todo o sistema

gStartX := 0
gStartY := 0

A_IconTip := "Mouse Gestures (AutoHotkey v2)"

A_TrayMenu.Delete()
A_TrayMenu.Add("Mouse Gestures", (*) => 0)
A_TrayMenu.Disable("Mouse Gestures")
A_TrayMenu.Add()
A_TrayMenu.Add("Suspender / Retomar`tCtrl+Alt+F12", (*) => Suspend(-1))
A_TrayMenu.Add("Recarregar script", (*) => Reload())
A_TrayMenu.Add()
A_TrayMenu.Add("Sair", (*) => ExitApp())


; ------------------------------------------------------------
;  HOTKEYS
; ------------------------------------------------------------

; Ctrl+Alt+F12 liga/desliga os gestos (quando suspenso, o botão
; direito volta a ser totalmente nativo).
^!F12::Suspend(-1)


#HotIf !GestureBlocked()

; Pressionar: apenas guarda a posição inicial e engole o evento,
; para que o menu de contexto não apareça durante o arrasto.
RButton::
{
    global gStartX, gStartY
    MouseGetPos &gStartX, &gStartY
}

; Soltar: decide entre gesto ou clique direito normal.
RButton Up::
{
    global gStartX, gStartY, threshold, maxHorizontal, focusUnderMouse

    MouseGetPos &endX, &endY
    dx := endX - gStartX
    dy := endY - gStartY

    verticalOk   := Abs(dy) >= threshold
    horizontalOk := (maxHorizontal = 0) || (Abs(dx) <= maxHorizontal)

    if (verticalOk && horizontalOk)
    {
        if (focusUnderMouse)
            ActivateWindowUnderMouse()

        if (dy < 0)
            Send "^{Home}"     ; arrastou para cima
        else
            Send "^{End}"      ; arrastou para baixo

        return
    }

    ; Movimento insuficiente: reproduz o clique direito comum.
    SendPlainRightClick()
}

#HotIf


; ------------------------------------------------------------
;  FUNÇÕES
; ------------------------------------------------------------

SendPlainRightClick()
{
    global clickDelay
    Send "{RButton down}"
    Sleep clickDelay
    Send "{RButton up}"
}

ActivateWindowUnderMouse()
{
    MouseGetPos , , &hwnd
    if (hwnd)
        try WinActivate "ahk_id " hwnd
}

GestureBlocked()
{
    global excludedWindows
    for target in excludedWindows
    {
        if WinActive(target)
            return true
    }
    return false
}
