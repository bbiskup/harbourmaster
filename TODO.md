
= UI

== Page frame

- Use toasts to indicate server errors and other messages?
  - see [toasty-bootstrap(https://package.elm-lang.org/packages/andrewjackman/toasty-bootstrap/latest/)
    - tests failing as of 20181230, but seems to be CI config issue (missing elm.json; the demo
      is working nicely)

== Info page

- link from '# of xxx (containers)' to container list with that particular filter applied?

== Container list

- sort by date?
- create invisible placeholder button to align buttons of the same kind horizontally
  - add buttons with a NoOp actoin, or just hide inappropriate buttons?
- Let restarting (and running?) states blink?
- Should "remove" use "force" option?
- Add column for exit code
  - need to parse 'Status' field
- Show number of containers


== Charts

- Pie chart (or similar): containers by size
- Pie chart (or similar): images by size
- Sparklines: https://github.com/jweir/sparkline

== Access control

- Implement password login
- two levels of access?
  - ReadOnly: allows browsing everything (only GET requests)
  - Full: allows starting, stopping, removing containers and images etc. (POST, DELETE)

