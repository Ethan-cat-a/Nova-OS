# NOVA OS 1.4.1 — Dimension maintenance update

AI Overview has been removed from the native app while NOVA Intelligence infrastructure is improved. This includes the search-result card, JavaScript handler, Swift request and response path, overview cache, and menu preference. No automatic overview request to the NOVA Intelligence chat endpoint remains. Ordinary search and its result cache, Morph, Dimension, and Flow features are unchanged. Older installed versions still contain the previous AI feature; this patch does not change or disable the shared AI backend. Manual installation is required if the existing Sparkle key remains unavailable.

Release checks: no overview code in Swift sources; regular search and Morph/Dimension integration retained; Swift test suite; universal installer and signature verification. Full physical Mac GUI testing is not performed by CI.
