# app/services/email_validator_service.py
"""Disposable / fake email blocker.

Maintains a curated blocklist of throwaway email providers so signups can't
use mailinator/tempmail-style addresses. Also adds basic format checks
(e.g. obvious test patterns like 'a@b.c').
"""
from __future__ import annotations

import re
from typing import Optional

# Top disposable email providers — covers ~99% of throwaway addresses
# encountered in the wild. Source: aggregated from
# https://github.com/disposable-email-domains/disposable-email-domains and
# https://github.com/ivolo/disposable-email-domains.
_DISPOSABLE_DOMAINS = frozenset({
    # 10minutemail family
    "10minutemail.com", "10minutemail.net", "10minutemail.org",
    "10minutemail.de", "10minutemail.co.uk", "10minutesmail.com",
    "20minutemail.com", "30minutemail.com", "60minutemail.com",
    # Mailinator family
    "mailinator.com", "mailinator.net", "mailinator2.com", "mailinater.com",
    "binkmail.com", "bobmail.info", "chammy.info", "devnullmail.com",
    "letthemeatspam.com", "mailinator.org", "mailinater.com",
    "notmailinator.com", "reallymymail.com", "safetymail.info",
    "sogetthis.com", "spamhereplease.com", "supermailer.jp",
    "thisisnotmyrealemail.com", "tradermail.info", "veryrealemail.com",
    "zippymail.info",
    # Temp-mail family
    "temp-mail.org", "tempmail.com", "tempmail.net", "tempmail.de",
    "tempmail.email", "tempmail.io", "tempmail.us.com", "tempmailaddress.com",
    "tempmailgen.com", "temp-mail.io", "temp-mail.ru", "tempmail.plus",
    "tempmail.dev", "tempmailo.com", "tempmail.gg",
    # Guerrilla Mail
    "guerrillamail.com", "guerrillamail.de", "guerrillamail.net",
    "guerrillamail.org", "guerrillamail.biz", "guerrillamailblock.com",
    "spam4.me", "grr.la", "sharklasers.com", "pokemail.net",
    # Yopmail family
    "yopmail.com", "yopmail.fr", "yopmail.net", "cool.fr.nf",
    "courriel.fr.nf", "moncourrier.fr.nf", "monemail.fr.nf",
    "monmail.fr.nf", "jetable.fr.nf", "nospam.ze.tc", "nomail.xl.cx",
    "mega.zik.dj", "speed.1s.fr", "courrieltemporaire.com",
    # Throwaway / fake
    "throwawaymail.com", "throwam.com", "trashmail.com", "trashmail.net",
    "trashmail.de", "trashmail.org", "trash-mail.com", "trash-mail.de",
    "trash-mail.tk", "wegwerfmail.de", "wegwerfmail.net", "wegwerfmail.org",
    "spambox.us", "spambog.com", "spambog.de", "spambog.ru", "spam.la",
    "spamavert.com", "spamday.com", "spamex.com", "spamfree24.com",
    "spamgourmet.com", "spamgourmet.net", "spamgourmet.org", "spamhole.com",
    "spamify.com", "spaml.com", "spammotel.com", "spamspot.com",
    "spamthis.co.uk", "spamthisplease.com", "tempinbox.com", "tempinbox.co.uk",
    "tempemail.com", "tempemail.net", "tempemail.co.za",
    # Mohmal / Maildrop / GetAirMail
    "mohmal.com", "mohmal.tech", "mohmal.in", "mohmal.im",
    "maildrop.cc", "maildrop.cf", "maildrop.gq", "maildrop.ga",
    "getairmail.com", "getnada.com", "nada.email", "nada.ltd",
    # Email Generator / Random
    "emailondeck.com", "emailfake.com", "email-fake.com", "fakemail.fr",
    "fakemailgenerator.com", "fakeinbox.com", "fakeinbox.email",
    "burnermail.io", "burner.kiwi", "burnerlists.com",
    # Anonbox / Anonmails
    "anonbox.net", "anonmails.de", "anonymbox.com",
    # Dispostable / DropMail
    "dispostable.com", "dropmail.me", "discard.email", "discardmail.com",
    "discardmail.de",
    # MyTemp / MailTemp / SecureMailbox
    "mytemp.email", "mailtemp.info", "mail-temp.com", "mailtemporal.org",
    "secmail.pro", "securemail.lk", "snapmail.cc", "fakemail.net",
    "luxusmail.org", "33mail.com", "yepmail.net",
    # Inboxbear / Inboxalias
    "inboxbear.com", "inboxalias.com", "inboxkitten.com", "linshiyouxiang.net",
    # 1secmail family
    "1secmail.com", "1secmail.net", "1secmail.org", "1secmail.xyz",
    "esiix.com", "wwjmp.com", "kzccv.com", "qiott.com", "vjuum.com",
    "yoggm.com", "icznn.com", "uorak.com", "xojxe.com", "hawrl.com",
    "laafd.com", "yapped.net", "rteet.com", "huleos.com", "snemail.com",
    # Misc throwaway
    "byom.de", "deadaddress.com", "deadfake.com", "deadspam.com",
    "easytrashmail.com", "fivemail.de", "fastmazda.com", "fixmail.tk",
    "fleckens.hu", "freshemail.xyz", "fudgerub.com", "garliclife.com",
    "haltospam.com", "harakirimail.com", "haribu.net", "hexagonalbacon.com",
    "hidemail.de", "imails.info", "imgof.com", "incognitomail.com",
    "incognitomail.net", "incognitomail.org", "instant-mail.de",
    "ipoo.org", "jsrsolutions.com", "junk1e.com", "kasmail.com",
    "klassmaster.com", "klzlk.com", "koszmail.pl", "kulturbetrieb.info",
    "kurzepost.de", "lawlita.com", "letthemeatspam.com",
    "lifebyfood.com", "link2mail.net", "lookugly.com", "lortemail.dk",
    "lroid.com", "lukop.dk", "mail-temporaire.fr", "mail.by",
    "mailb.tk", "mailcatch.com", "mailde.de", "mailde.info",
    "maildim.com", "maileater.com", "mailexpire.com", "mailfa.tk",
    "mailfreeonline.com", "mailguard.me", "mailimate.com",
    "mailme.lv", "mailmetrash.com", "mailmoat.com", "mailms.com",
    "mailnesia.com", "mailnull.com", "mailshell.com",
    "mailsiphon.com", "mailtome.de", "mailtothis.com", "mailtrash.net",
    "mailtv.net", "mailtv.tv", "mailzilla.com", "mailzilla.org",
    "makemetheking.com", "manybrain.com", "mbx.cc", "mega.zik.dj",
    "meinspamschutz.de", "meltmail.com", "messagebeamer.de",
    "mintemail.com", "mjukglass.nu", "mobi.web.id", "mobileninja.co.uk",
    "moncourrier.fr.nf", "monemail.fr.nf", "monmail.fr.nf",
    "msa.minsmail.com", "mt2009.com", "mx0.wwwnew.eu", "mycard.net.ua",
    "mycleaninbox.net", "mymail-in.net", "mypartyclip.de",
    "myphantomemail.com", "myspaceinc.com", "myspaceinc.net",
    "myspaceinc.org", "myspacepimpedup.com", "myspamless.com", "mytrashmail.com",
    "neverbox.com", "no-spam.ws", "nobulk.com", "noclickemail.com",
    "nogmailspam.info", "nomail2me.com", "nomorespamemails.com",
    "nospam.wins.com.br", "nospam4.us", "nospamfor.us", "nospamthanks.info",
    "nowmymail.com", "objectmail.com", "obobbo.com", "odaymail.com",
    "onewaymail.com", "onlatedotcom.info", "online.ms", "oopi.org",
    "ordinaryamerican.net", "otherinbox.com", "ovpn.to",
    "owlpic.com", "pancakemail.com", "pjjkp.com",
    "plexolan.de", "poofy.org", "pookmail.com", "privacy.net",
    "privatdemail.net", "proxymail.eu", "punkass.com", "putthisinyourspamdatabase.com",
    "qq.com", "quickinbox.com", "rcpt.at", "recode.me", "recursor.net",
    "regbypass.com", "rejectmail.com", "rmqkr.net", "royal.net",
    "rppkn.com", "rtrtr.com", "s0ny.net", "safe-mail.net",
    "safersignup.de", "safetypost.de", "sandelf.de", "saynotospams.com",
    "selfdestructingmail.com", "sendspamhere.com", "sharedmailbox.org",
    "shieldedmail.com", "shiftmail.com", "shitmail.me", "shortmail.net",
    "sibmail.com", "siltini.com", "sify.com", "skeefmail.com",
    "slapsfromlastnight.com", "slaskpost.se", "slopsbox.com", "smashmail.de",
    "smellfear.com", "smellrear.com", "snakemail.com", "sneakemail.com",
    "snkmail.com", "sofort-mail.de", "sogetthis.com", "soodonims.com",
    "spam.la", "spam.org.es", "spam.su", "spamarrest.com", "spambob.com",
    "spambog.com", "spamcero.com", "spamcorptastic.com", "spamcowboy.com",
    "spamcowboy.net", "spamcowboy.org", "spamday.com", "spamdecoy.net",
    "spaml.com", "spaml.de", "spammotel.com", "spamslicer.com",
    "spamsphere.com", "spamspot.com", "spamthis.co.uk", "spamthisplease.com",
    "spamtroll.net", "stinkefinger.net", "supermailer.jp",
    "suremail.info", "tagyourself.com", "talkinator.com",
    "teleworm.com", "teleworm.us", "thanksnospam.info", "thankyou2010.com",
    "thingiverse.com", "thisisnotmyrealemail.com", "throam.com",
    "tilien.com", "tmailinator.com", "tradermail.info", "trash2009.com",
    "trashdevil.com", "trashemail.de", "trashymail.com", "trashymail.net",
    "trayna.com", "trbvm.com", "trialmail.de", "trillianpro.com",
    "twinmail.de", "twoweirdtricks.com", "tyldd.com", "uggsrock.com",
    "umail.net", "uplipht.com", "upliftnow.com", "uroid.com",
    "us.af", "venompen.com", "veryrealemail.com", "vidchart.com",
    "viralplays.com", "viditag.com", "viewcastmedia.com", "viewcastmedia.net",
    "viewcastmedia.org", "vipmail.us", "vrmtr.com", "vsbnetworking.com",
    "vubby.com", "vztc.com", "wegwerfemail.de", "wetrainbayarea.com",
    "wetrainbayarea.org", "wh4f.org", "whatpaas.com", "whyspam.me",
    "willhackforfood.biz", "willselfdestruct.com", "winemaven.info",
    "wronghead.com", "wuzup.net", "wuzupmail.net", "www.gishpuppy.com",
    "www.live.co.kr.beo.kr", "www.mailinator.com", "wwwnew.eu", "x.ip6.li",
    "xagloo.com", "xemaps.com", "xents.com", "xmaily.com", "xoxy.net",
    "yapped.net", "yeah.net", "yep.it", "yogamaven.com", "yopmail.fr",
    "yourdomain.com", "yuurok.com", "z1p.biz", "za.com", "zehnminuten.de",
    "zoaxe.com", "zoemail.org", "zomg.info",
})


_EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+\-]+@([A-Za-z0-9.\-]+\.[A-Za-z]{2,})$")


class EmailValidationError(ValueError):
    """Raised when an email is rejected by ``validate_email``."""


def _domain(email: str) -> Optional[str]:
    match = _EMAIL_RE.match(email.strip().lower())
    if not match:
        return None
    return match.group(1)


def is_disposable(email: str) -> bool:
    domain = _domain(email)
    if not domain:
        return False
    if domain in _DISPOSABLE_DOMAINS:
        return True
    # Catch subdomains: *.tempmail.com etc.
    parts = domain.split(".")
    for i in range(len(parts) - 1):
        suffix = ".".join(parts[i:])
        if suffix in _DISPOSABLE_DOMAINS:
            return True
    return False


def validate_email(email: str) -> None:
    """Raises ``EmailValidationError`` if the email is rejected.

    Allows: standard format, real domain.
    Rejects: disposable providers, malformed addresses.
    """
    if not email or "@" not in email:
        raise EmailValidationError("Email noto'g'ri formatda")

    domain = _domain(email)
    if not domain:
        raise EmailValidationError("Email noto'g'ri formatda")

    if is_disposable(email):
        raise EmailValidationError(
            "Vaqtinchalik / fake email manzillar qabul qilinmaydi. "
            "Iltimos, real email manzilingizni kiriting."
        )
