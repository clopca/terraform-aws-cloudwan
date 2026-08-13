# Compact one-state composition

Composes the root fabric, `policy-deployment`, and optional `core-network-share`
modules directly in one state. The RAM provider is named by role (`aws.ram`), and
setting `sharing = null` leaves no share module instance or RAM association in
state. This is the supported compact UX; there is no separate stack facade.
