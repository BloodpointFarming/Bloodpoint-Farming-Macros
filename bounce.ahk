#Requires AutoHotkey v2+

useItemButton := "RButton"

~Space:: {
    Send(buttonify(useItemButton))
    Sleep(500)
    Send(buttonify(useItemButton))
}

buttonify(button) => "{" button "}"