(*
  Creates a Papyrus comment banner from the text at the clipboard.
*)

#r "nuget: TextCopy"

let content = TextCopy.ClipboardService.GetText()
let sep = ";>========================================================"
let startS = ";>==="
let endS = "===<;"

let leftS =
    " "
        .PadRight(
            (sep.Length / 2)
            - startS.Length
            - (content.Length / 2)
            - 1
        )

let rightS = " ".PadRight(leftS.Length + (content.Length % 2))

let banner = startS + leftS + content.ToUpper() + rightS + endS

$"{sep}\n{banner}\n{sep}"
|> TextCopy.ClipboardService.SetText
