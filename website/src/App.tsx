import { useEffect, useRef, useState, type CSSProperties, type PointerEvent } from 'react';
import GuideDialog, { type GuidePage } from './GuideDialog';
import { Icon } from './Icons';

const destinations = {
  curseforge: 'https://www.curseforge.com/wow/addons/alwaysbuffed',
  wago: 'https://addons.wago.io/addons/alwaysbuffed',
  release: 'https://github.com/SPDUK/AlwaysBuffed/releases/latest',
  source: 'https://github.com/SPDUK/AlwaysBuffed',
};
const scenes = [
  {
    image: 'hero',
    name: 'Ashenvale',
    alt: 'Blue shafts of light fall through the ancient trees of Ashenvale in World of Warcraft: Forever.',
  },
  {
    image: 'dalaran',
    name: 'Dalaran',
    alt: 'The towers of Dalaran rise above a wooded road at sunset in World of Warcraft: Forever.',
  },
  {
    image: 'riverglades',
    name: 'The Riverglades',
    alt: 'The setting sun reflects on the river beside a ship in the Riverglades.',
  },
];
const nav = [
  { id: 'overview', text: 'Overview' },
  { id: 'field-guide', text: 'Field guide' },
  { id: 'install', text: 'Installation' },
  { id: 'faq', text: 'FAQ' },
];

function Brand() {
  return (
    <a className="brand" href="#overview" aria-label="AlwaysBuffed home">
      <img src={import.meta.env.BASE_URL + "icon.png"} width="34" height="34" alt="" />
      <span>AlwaysBuffed</span>
    </a>
  );
}

function Header() {
  const [active, setActive] = useState('overview');
  const menu = useRef<HTMLDetailsElement>(null);
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) if (entry.isIntersecting) setActive(entry.target.id);
      },
      { rootMargin: '-5% 0px -67%' },
    );
    for (const { id } of nav) {
      const section = document.getElementById(id);
      if (section) observer.observe(section);
    }
    return () => observer.disconnect();
  }, []);
  function closeMenu() {
    if (menu.current) menu.current.open = false;
  }
  const links = nav.map(({ id, text }) => (
    <a href={'#' + id} key={id} aria-current={active === id ? 'location' : undefined} onClick={closeMenu}>
      {text}
    </a>
  ));
  return (
    <header className="site-header">
      <div className="container header-inner">
        <Brand />
        <nav className="desktop-nav" aria-label="Sections">
          {links}
        </nav>
        <a className="nav-cta" href="#install">
          <Icon name="download" size={15} /> Get the addon
        </a>
        <details
          ref={menu}
          className="mobile-menu"
          onKeyDown={(event) => {
            if (event.key === 'Escape') {
              closeMenu();
              menu.current?.querySelector('summary')?.focus();
            }
          }}
        >
          <summary aria-label="Navigation menu">
            <Icon name="menu" />
          </summary>
          <nav aria-label="Mobile sections">{links}</nav>
        </details>
      </div>
    </header>
  );
}

function Downloads() {
  return (
    <div className="downloads">
      <a className="download-button primary" href={destinations.curseforge}>
        <Icon name="forge" size={24} />
        <span>Visit CurseForge</span>
        <Icon name="external" size={15} />
      </a>
      <a className="download-button secondary" href={destinations.wago}>
        <Icon name="wago" size={23} />
        <span>Visit Wago</span>
        <Icon name="external" size={15} />
      </a>
    </div>
  );
}

const screenshots = {
  rankings: {
    src: import.meta.env.BASE_URL + 'screenshots/food.webp',
    alt: 'AlwaysBuffed ranks food for a Survival hunter and compares the recommended purchase with the best item in bags.',
    width: 1001,
    height: 651,
  },
  shopping: {
    src: import.meta.env.BASE_URL + 'screenshots/shopping.webp',
    alt: 'AlwaysBuffed shopping list shows recommended consumables, real bag counts, and cached auction prices.',
    width: 1001,
    height: 651,
  },
  wheel: {
    src: import.meta.env.BASE_URL + 'screenshots/wheel.webp',
    alt: 'AlwaysBuffed radial wheel in Southshore, with gold borders on active weapon buffs and Well-Rested.',
    width: 430,
    height: 432,
  },
} satisfies Record<GuidePage, { src: string; alt: string; width: number; height: number }>;

function GameplayScreenshot({ page, className, eager = false }: {
  page: GuidePage;
  className: string;
  eager?: boolean;
}) {
  const screenshot = screenshots[page];
  return (
    <a className={className} href={screenshot.src} aria-label={`View full screenshot. ${screenshot.alt}`}>
      <img {...screenshot} loading={eager ? 'eager' : 'lazy'} decoding="async" />
    </a>
  );
}

function Hero() {
  const [current, setCurrent] = useState(0);
  const scene = scenes[current];
  function moveView(event: PointerEvent<HTMLElement>) {
    if (event.pointerType !== 'mouse' || window.matchMedia('(prefers-reduced-motion: reduce)').matches)
      return;
    const section = event.currentTarget;
    const bounds = section.getBoundingClientRect();
    section.style.setProperty(
      '--look-x',
      (8 * ((event.clientX - bounds.left) / bounds.width - 0.5)).toFixed(1) + 'px',
    );
    section.style.setProperty(
      '--look-y',
      (6 * ((event.clientY - bounds.top) / bounds.height - 0.5)).toFixed(1) + 'px',
    );
  }
  function changeScene(direction: number) {
    setCurrent((previous) => (previous + direction + scenes.length) % scenes.length);
  }
  return (
    <section
      className="hero"
      id="overview"
      aria-labelledby="hero-heading"
      onPointerMove={moveView}
      onPointerLeave={(event) => {
        event.currentTarget.style.removeProperty('--look-x');
        event.currentTarget.style.removeProperty('--look-y');
      }}
    >
      <picture key={scene.image} className="hero-scene">
        <source media="(max-width: 760px)" srcSet={import.meta.env.BASE_URL + 'art/' + scene.image + '-small.webp'} />
        <img
          src={import.meta.env.BASE_URL + 'art/' + scene.image + '.webp'}
          alt={scene.alt}
          width="1920"
          height="1080"
          fetchPriority="high"
        />
      </picture>
      {current === 0 && (
        <div className="forest-light" aria-hidden="true">
          {[
            [49, 57],
            [53, 39],
            [58, 67],
            [62, 25],
            [69, 52],
            [73, 74],
            [80, 32],
            [86, 56],
            [93, 44],
          ].map(([x, y], index) => (
            <i
              key={x}
              style={{ left: x + '%', top: y + '%', '--delay': -index * 1.7 + 's' } as CSSProperties}
            />
          ))}
        </div>
      )}
      <div className="hero-shade" />
      <div className="container hero-layout">
        <div className="hero-copy">
          <div className="game-title">
            <span className="rune-line" />
            World of Warcraft: Forever
          </div>
          <h1 id="hero-heading">
            <span className="sr-only">AlwaysBuffed. </span>Less prep.
            <br /> <em>More adventure.</em>
          </h1>
          <p>
            <strong>AlwaysBuffed</strong> finds the right consumables for your spec, shows what’s in your
            bags, and puts your next buff one click away.
          </p>
          <Downloads />
          <div className="download-status">
            <a href={destinations.release}>Download on GitHub <Icon name="external" size={12} /></a>
          </div>
        </div>
        <figure className="hero-gameplay">
          <GameplayScreenshot page="shopping" className="gameplay-frame" eager />
          <figcaption>A Survival hunter’s shopping list in WoW Forever.</figcaption>
        </figure>
        <div className="location">
          <Icon name="pin" size={15} />
          <span aria-live="polite">{scene.name}</span>
          <div className="scene-pager">
            <button type="button" aria-label="Previous location" onClick={() => changeScene(-1)}>
              <Icon name="left" size={13} />
            </button>
            <span>
              {current + 1} / {scenes.length}
            </span>
            <button type="button" aria-label="Next location" onClick={() => changeScene(1)}>
              <Icon name="right" size={13} />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}

function Facts() {
  return (
    <div className="facts">
      <dl className="container facts-inner">
        {[
          ['book', '358', 'Items & spells'],
          ['layers', '34', 'Buff categories'],
          ['compass', '28', 'Spec presets'],
        ].map(([icon, number, name]) => (
          <div key={name}>
            <dt>
              <Icon name={icon as 'book' | 'layers' | 'compass'} size={28} />
              <span>{name}</span>
            </dt>
            <dd>{number}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

const guides = [
  {
    id: 'rankings',
    title: 'Find your best buffs',
    body: 'Compare eligible food and elixirs for your spec without reading every tooltip.',
    action: 'Compare two specs',
  },
  {
    id: 'shopping',
    title: 'Know what to buy',
    body: 'See what you carry beside cached auction prices before you spend your gold.',
    action: 'Try the shopping list',
  },
  {
    id: 'wheel',
    title: 'Buff before the pull',
    body: 'Hold your wheel shortcut, aim at a slice, and release to use a carried item outside combat.',
    action: 'Try the buff wheel',
  },
] as const;

function FieldGuide({ open }: { open: (page: GuidePage) => void }) {
  return (
    <section id="field-guide" className="field-guide container" aria-labelledby="guide-heading">
      <div className="section-heading">
        <div>
          <h2 id="guide-heading">
            The field guide<span>.</span>
          </h2>
          <p>See how AlwaysBuffed looks in game, then try the interactive examples.</p>
        </div>
        <span className="heading-ornament" aria-hidden="true">
          <i />
          <Icon name="book" size={20} />
          <i />
        </span>
      </div>
      <div className="guide-grid">
        {guides.map((guide, i) => (
          <article className="feature" key={guide.id}>
            <GameplayScreenshot page={guide.id} className={`guide-screenshot ${guide.id}`} />
            <div className="feature-copy">
              <span className="guide-step">
                <i />
                {['Spec rankings', 'Shopping list', 'Buff wheel'][i]}
              </span>
              <h3>{guide.title}</h3>
              <p>{guide.body}</p>
              <button
                className="text-action"
                type="button"
                aria-haspopup="dialog"
                onClick={() => open(guide.id)}
              >
                {guide.action}
                <Icon name="arrow" size={16} />
              </button>
            </div>
          </article>
        ))}
      </div>
      <noscript>
        <p className="guide-fallback">
          <a href={destinations.source + '#in-game'}>Read the in-game controls and full addon guide</a>
        </p>
      </noscript>
    </section>
  );
}

const questions = [
  [
    'How do I switch to Fishing or another profession?',
    <>Type <code>/alwaysbuffed</code> or <code>/ab</code> and select <strong>Professions</strong>.
      In <strong>Automatic</strong> mode, equipping any fishing pole switches your bar, wheel, and shopping
      list to Fishing. Putting it away restores Combat. Track lures such as Nightcrawlers, fishing food,
      the Shiny Silver Coin, and Fishing Rack or Hut bonuses under <strong>Utility</strong>.
      Mages can select Comprehension to track its skill scroll.</>,
  ],
  [
    'Where does Herbalism Tea appear?',
    <>Look on the default Combat bar. Trained herbalists start with the reminder enabled. Anyone can change
      it under <strong>Professions → Herbalism Tea</strong>, with Find Herbs on or off. Drink Goldthorn Tea
      for 10 seconds to gain +15 Herbalism for 15 minutes. Version 1.1.1 removed the hidden-herb and
      hidden-mining reminders. Characters who had selected either gathering bar return to Automatic.</>,
  ],
  [
    'Can other gear switch me to the Fishing bar?',
    <>Type <code>/ab fishgear</code> followed by an item link or ID. Equipping that item selects Fishing
      in <strong>Automatic</strong> mode. Use <code>/ab fishgear clear</code> to remove it.
      Both commands also work with <code>/alwaysbuffed</code>. Applying a lure requires a fishing pole.</>,
  ],
  [
    'Which way can the bar expand?',
    <>In <strong>General → Icons grow</strong>, choose Left, Right, Up, or Down. Click the grip to fold
      the icons back into the same spot.</>,
  ],
  [
    'Which languages does the addon support?',
    'AlwaysBuffed follows your WoW client language. It supports English, German, Spanish (Spain and Latin America), French, Italian, Korean, Brazilian Portuguese, Russian, Simplified Chinese, and Traditional Chinese.',
  ],
  [
    'Which version of WoW does AlwaysBuffed support?',
    'AlwaysBuffed is built for World of Warcraft: Forever. Install the package ending in -forever.zip in your Forever client.',
  ],
  [
    'Do I need Auctionator?',
    'Auctionator is optional. To show auction prices, install its Forever version and run Full Scan at the auction house. Rankings, bag counts, the bar, and the wheel work independently.',
  ],
  [
    'How does the addon choose a spec?',
    'Auto follows the talent group with the most committed points. Before you spend points, your class has a leveling default. Choose a named profile to plan for another build.',
  ],
  [
    'Can I use the buffs in combat?',
    'The buff bar keeps the actions it prepared before combat, subject to each item’s use restrictions. The wheel opens outside combat. Secure assignments refresh when combat ends.',
  ],
] as const;
function Install() {
  return (
    <section id="install" className="install-panel" aria-labelledby="install-heading">
      <div className="container install-layout">
        <div>
          <h2 id="install-heading">
            Get AlwaysBuffed<span>.</span>
          </h2>
          <p>Pick up the Forever build for your next trip through Azeroth.</p>
          <Downloads />
          <p className="release-note">
            <a href={destinations.release}>
              Download the current release on GitHub <Icon name="external" size={12} />
            </a>
          </p>
        </div>
        <ol className="install-steps">
          <li>
            <strong>Download the Forever ZIP</strong>
            <p>
              Choose the release file ending in <code>-forever.zip</code>.
            </p>
          </li>
          <li>
            <strong>Extract the addon</strong>
            <p>
              Close WoW and place the <code>AlwaysBuffed</code> folder in{' '}
              <code>_forever_/Interface/AddOns/</code>.
            </p>
          </li>
          <li>
            <strong>Open your first recommendation</strong>
            <p>
              Enable AlwaysBuffed at character select. In game, type <code>/alwaysbuffed</code> or{' '}
              <code>/ab</code> in chat. Choose <b>Food</b> for your first recommendation or{' '}
              <b>Professions</b> to set up a gathering bar.
            </p>
          </li>
        </ol>
      </div>
    </section>
  );
}

export default function App() {
  const [page, setPage] = useState<GuidePage | null>(null);
  return (
    <>
      <a href="#main" className="skip">
        Skip to content
      </a>
      <Header />
      <main id="main">
        <Hero />
        <Facts />
        <FieldGuide open={setPage} />
        <Install />
        <section className="faq container" id="faq" aria-labelledby="faq-heading">
          <h2 id="faq-heading">
            Common questions<span>.</span>
          </h2>
          <div>
            {questions.map(([q, a]) => (
              <details key={q}>
                <summary>
                  {q}
                  <Icon name="plus" size={18} />
                </summary>
                <p>{a}</p>
              </details>
            ))}
          </div>
        </section>
      </main>
      <footer className="footer">
        <div className="container">
          <div className="footer-row">
            <Brand />
            <nav aria-label="Project links">
              <a href={destinations.source}>
                Source v{__ADDON_VERSION__} <Icon name="external" size={12} />
              </a>
              <a href={destinations.source + '/issues'}>
                Report an issue <Icon name="external" size={12} />
              </a>
            </nav>
          </div>
          <p>
            Addon by SPDUK · GPL-3.0-only. World of Warcraft imagery © Blizzard Entertainment.{' '}
            <a href="https://blizzard.gamespress.com/Kit/Details/WoW-Forever-Launch-Press-Kit">
              Screenshot credits
            </a>
          </p>
        </div>
      </footer>
      <GuideDialog page={page} onClose={() => setPage(null)} />
    </>
  );
}
