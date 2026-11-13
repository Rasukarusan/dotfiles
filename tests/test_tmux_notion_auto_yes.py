import runpy
import unittest
from pathlib import Path


approval = runpy.run_path(
    str(Path(__file__).resolve().parents[1] / "bin" / "tmux-notion-auto-yes")
)["approval"]

MENU = """

Do you want to proceed?
❯ 1. Yes
  2. No

Esc to cancel · Tab to amend · ctrl+x ctrl+k twice to stop background agents
"""
NOTION = """About the Notion — Notion-Update-Page Tool:
│ Update a Notion page's properties, content, icon, or cover.
│ ## Core rules…
(ctrl+o to expand description)

Your organization requires approval for this tool
"""
RM = """│ Dangerous rm operation on possibly-empty variable path: $OUT/*.png in `rm -f $OUT/*.png`
⚠Claude Code will automatically block this request in 1:44, to avoid holding up an unattended session
"""


class ApprovalTest(unittest.TestCase):
    def test_dialogs(self):
        cases = [
            (NOTION + MENU, True),
            (NOTION + MENU + "\n\n", True),
            (NOTION.replace("│ ## Core rules…", "") + MENU, True),
            (NOTION.replace("Notion — Notion-Update-Page", "Slack – メッセージにリアクションを追加する") + MENU, True),
            (NOTION.replace("Notion — Notion-Update-Page", "Slack – メッセージを送信する") + MENU, False),
            (NOTION.replace("Notion — Notion-Update-Page", "Other – execute") + MENU, False),
            (NOTION.replace("Your organization requires approval for this tool", "Description only") + MENU, False),
            (NOTION + MENU + "Command finished\n", False),
            (NOTION + MENU + "\nAbout the Other – execute Tool:\n" + NOTION.split("\n\n")[-1] + MENU, False),
            (NOTION + MENU.replace("2. No", "2. Always allow"), False),
            (RM + MENU, True),
            (RM.replace("possibly-empty variable path", "protected path") + MENU, False),
            (RM.splitlines()[0] + MENU, False),
            (RM + MENU + "\nOther command\n" + MENU, False),
        ]
        for screen, expected in cases:
            with self.subTest(screen=screen):
                self.assertEqual(approval(screen), expected)


if __name__ == "__main__":
    unittest.main()
