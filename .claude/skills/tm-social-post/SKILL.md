---
name: tm-social-post
description: Post a finished Toastmasters recap video to a Facebook Page and a personal LinkedIn profile, with an AI-drafted caption the user approves first. Use after the recap video is built and verified, or when asked to share/publish/post the promo video.
---

# Post the recap video

Drives the user's already-signed-in browser through Claude in Chrome. No API keys, no
OAuth app, no tokens, which is why this skill ships in a public repo safely. It also
means every post goes out as the user, from their own session, so the standard applies:
**you prepare, they approve, then it posts.**

Invoke the `claude-in-chrome` skill first, then load the browser tools in ONE ToolSearch
call. You will need at minimum: `tabs_context_mcp`, `tabs_create_mcp`, `navigate`,
`computer`, `read_page`, `find`, `file_upload`, `tabs_close_mcp`.

## Gate: do not start until all four are true

1. The video is built **and verified**: cards proofread, contact sheet checked. Posting
   is the one step that cannot be undone; a misspelled name goes public.
2. **Written permission from every person who appears**, guardians for minors. Ask the
   user to confirm this out loud. Do not infer it from the video existing.
3. The user has said which Facebook Page. Never guess from what happens to be open.
4. The user knows this posts publicly. If they have not seen the final video in this
   session, show it to them first.

If the club submits to <brand@toastmasters.org> before publishing, that approval belongs
here too, so ask whether it has come back.

## 1. Draft the caption

Read `meeting.conf` for the facts. Draft in the Toastmasters voice recorded in
`tm-brand`: confident, friendly-professional, positive, upbeat, succinct, internationally
friendly.

**Names and awards are copied verbatim from `meeting.conf`. They are never paraphrased,
re-capitalised, or written from memory of the conversation.** This is the same rule the
video pipeline runs on. A model may write the sentences around a name, never the name.
After drafting, diff every person's name in your draft against `WINNERn_NAME`
character by character and fix any drift before showing the user.

Constraints on the copy:

- **One approved phrase, maximum**, and only if `PHRASE` in `meeting.conf` isn't already
  carrying it in the video. See `brand-cheatsheet.md` for the allowed list.
- No invented club taglines, no invented statistics, no claims about the club that
  `meeting.conf` and the user have not supplied.
- Don't restate what the video already shows. The caption gives someone scrolling a
  reason to stop, the video does the rest.
- Include the club URL from `CLUB_URL`.
- Hashtags: a short, sane set. `#Toastmasters #PublicSpeaking` plus the club's city is
  usually enough.
- **Name the speaker, the evaluator and the winners, then tag them.** A tag notifies the
  person, and their reply carries the post into a network the club cannot reach on its
  own. This is the highest-leverage line in this file for reach, and it costs nothing.
  See "Tagging" below, because it is easy to get wrong.
- **Close on one specific question.** A recap that only reports is a recap nobody
  answers, and distribution on both platforms is driven by replies rather than by views.
  Ask something the meeting itself already asked, so the question reads as a continuation
  rather than as engagement bait: a "Back to School" meeting that opened by asking people
  about a favourite teacher ends its caption by asking the reader the same thing. Name
  the action plainly ("tell us in the comments"), and ask for a comment rather than a
  like, because a comment travels and a like mostly does not.

Write one caption per platform, not one shared caption:

- **Facebook Page**: warmer, community-facing, guests welcome, meeting details useful to
  a local reader.
- **Personal LinkedIn**: first person, professional register, what the user took from the
  meeting or why they volunteer. A club recap reposted verbatim to a personal feed reads
  like an advert; a personal note about the club reads like a person.

Show both drafts to the user as text in chat and let them edit before any browser work.
Do not paste an unapproved draft into a composer "so they can see it in place."

## 2. Tagging

Tags do more for reach than anything else here, and a wrong one is a public mistake about
someone else's achievement, so they get their own step.

- **Collect profile URLs before opening a composer.** Ask the user for the profile of
  every person about to be tagged. Never search a name and take the top hit.
- **Verify every pick against the URL the user gave you.** Autocomplete shows a name and
  a headline, never a URL, so when several candidates share a name, screenshot the list
  and ask the user which one. Ranking is not a shortcut: on LinkedIn a 1st degree
  connection can sit below three strangers with the same name.
- **Tag while composing, never by editing afterwards.** A mention added in an edit often
  fails to notify the person, which buys the link and loses the notification, and the
  notification is the part that does the work. If the post is already live, put the tags
  in a comment instead. Mentions in comments notify reliably, and the comment is itself a
  distribution signal.
- **Someone does not have to be a connection to be tagged.** Mentions resolve against any
  public profile. People can switch off being tagged in their privacy settings, so a name
  that will not resolve is usually a setting rather than a typo. Move on and say so.
- The same consent that covers appearing in the video does not automatically cover being
  tagged by name. If the user has not said who to tag, ask.

## 3. Facebook Page

1. Open a new tab to the Page, or to business.facebook.com if they use Business Suite.
2. Confirm the composer is posting **as the Page**, not as the user's personal profile.
   Read it back to the user if there is any ambiguity. Posting a club video to a personal
   timeline by accident is a real and annoying failure.
3. Attach the `.mp4` with `file_upload`.
4. Paste the approved caption.
5. Wait for the video to finish processing. A composer that still shows a progress bar
   will either reject the post or publish without the video.
6. **Screenshot the composer and show the user exactly what will go out. Ask for explicit
   confirmation. Only then click Post.**

## 4. Personal LinkedIn

1. New tab to linkedin.com, start a post, choose the video option.
2. Attach the same `.mp4`.
3. Paste the LinkedIn caption.
4. Insert the mentions now, not later: type `@` and the full name, check the candidate
   against the profile URL, then select it. Confirm each one rendered as a blue mention
   and not as plain text before moving on.
5. Check the audience selector: "Anyone" for a club promo, unless the user says otherwise.
6. LinkedIn re-encodes; wait for the preview thumbnail before continuing.
7. **Screenshot, confirm with the user, then post.**

## Hard rules

- **Never click Post, Publish, or Share without a fresh, explicit yes in chat for that
  specific post.** Approval of the caption is not approval to publish. Approval of the
  Facebook post is not approval of the LinkedIn post.
- Never accept a cookie/consent dialog, change an account setting, or dismiss a security
  prompt on the user's behalf. Surface it and let them do it.
- Avoid anything that triggers a browser modal; those freeze the extension.
- If a platform asks for a password or a 2FA code, stop and hand control back. Never type
  credentials.
- If the DOM has changed and you cannot find the composer after two or three attempts,
  stop and describe what you see. Do not click hopefully.
- Report the resulting post URLs back to the user.

## After posting

Remind the user that the video should also be submitted to <brand@toastmasters.org> if the
club has not already done so, and note anything worth changing next week: a caption that
ran long, a thumbnail frame that landed badly, a winner tile that read poorly at feed size.

Engagement is the number worth watching, not views. Views mean the platform showed the
post to someone; comments and reposts are what make it show the post to anyone new. If a
recap pulls hundreds of views and single-digit engagement week after week, the fix is in
the caption, the tags and the question, not in the video.
