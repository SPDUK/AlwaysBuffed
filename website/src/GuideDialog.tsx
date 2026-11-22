import { useEffect, useId, useRef, useState } from 'react';
import './guide-dialog.css';

export type GuidePage = 'rankings' | 'shopping' | 'wheel';

const pages = {
  rankings: {
    title: 'Ranked for your spec',
    description: 'Compare the same elixirs across two level 60 profiles.',
  },
  shopping: {
    title: 'From bags to buy list',
    description: 'Compare what a level 60 Fury Warrior carries with the last cached unit price.',
  },
  wheel: {
    title: 'Use the buff wheel',
    description: 'Choose a slice to try a sample item and its buff timer.',
  },
} satisfies Record<GuidePage, { title: string; description: string }>;

const elixirs = {
  mongoose: { name: 'Elixir of the Mongoose', effect: '+25 Agility · +2% Crit', count: 0, price: 24000 },
  strength: { name: 'Elixir of Greater Strength', effect: '+25 Strength', count: 4, price: 8000 },
  cunning: { name: 'Elixir of Cunning', effect: '+25 Agility · +25 Intellect', count: 2, price: null },
};

type Elixir = keyof typeof elixirs;
type Spec = 'fury' | 'marksmanship';
type RankedElixir = { item: Elixir; group: 'best' | 'not useful' };

const specs = {
  fury: {
    label: 'Fury Warrior',
    note: 'Flurry rewards critical hits, putting Mongoose ahead of Greater Strength.',
    ranking: [
      { item: 'mongoose', group: 'best' },
      { item: 'strength', group: 'best' },
      { item: 'cunning', group: 'best' },
    ],
  },
  marksmanship: {
    label: 'Marksmanship Hunter',
    note: 'Careful Aim converts Intellect into attack power, putting Cunning ahead of Mongoose.',
    ranking: [
      { item: 'cunning', group: 'best' },
      { item: 'mongoose', group: 'best' },
      { item: 'strength', group: 'not useful' },
    ],
  },
} satisfies Record<
  Spec,
  {
    label: string;
    note: string;
    ranking: [RankedElixir, ...RankedElixir[]];
  }
>;

const specChoices: Spec[] = ['fury', 'marksmanship'];

function RankingsExample() {
  const [spec, setSpec] = useState<Spec>('fury');
  const groupId = useId();
  const { note, ranking } = specs[spec];

  return (
    <>
      <fieldset className="guide-profiles">
        <legend>Profile</legend>
        <div className="guide-profile-options">
          {specChoices.map((choice) => (
            <label key={choice}>
              <input type="radio" name={groupId} checked={spec === choice} onChange={() => setSpec(choice)} />
              {specs[choice].label}
            </label>
          ))}
        </div>
      </fieldset>
      <ol className="guide-ranking" role="list" aria-label="Sample elixir rankings">
        {ranking.map(({ item, group }, index) => (
          <li key={item}>
            <span className="guide-rank" aria-hidden="true">
              {group === 'best' ? index + 1 : '—'}
            </span>
            <img className="guide-icon" src={`${import.meta.env.BASE_URL}icons/${item}.jpg`} width="36" height="36" alt="" />
            <span className="guide-item">
              <strong>{elixirs[item].name}</strong>
              <span>{elixirs[item].effect}</span>
            </span>
            {group === 'not useful' && <span className="guide-rank-group">Not useful</span>}
          </li>
        ))}
      </ol>
      <p className="guide-result" role="status">
        {note}
      </p>
      <p className="guide-in-game">
        In game, type <code>/alwaysbuffed</code> or <code>/ab</code> and select <strong>Elixir</strong>. Choose <strong>Auto</strong> to follow your
        talents or pick a named profile.
      </p>
    </>
  );
}

function UnitPrice({ price }: { price: number | null }) {
  if (price === null) {
    return (
      <span aria-label="No cached price" className="guide-price-empty">
        —
      </span>
    );
  }
  const gold = Math.floor(price / 10000);
  const silver = Math.floor((price % 10000) / 100);
  return (
    <span className="guide-price">
      {gold > 0 && (
        <abbr className="guide-gold" title={`${gold} gold`}>
          {gold}g
        </abbr>
      )}
      <abbr className="guide-silver" title={`${silver} silver`}>
        {silver}s
      </abbr>
    </span>
  );
}

function ShoppingExample() {
  const [lowestPrice, setLowestPrice] = useState(false);
  const ranking = specs.fury.ranking;
  const [best] = ranking;
  const cheapest = ranking.reduce<RankedElixir | null>((lowest, row) => {
    const price = elixirs[row.item].price;
    const lowestKnown = lowest && elixirs[lowest.item].price;
    if (row.group === 'best' && price !== null && (lowestKnown === null || price < lowestKnown)) {
      return row;
    }
    return lowest;
  }, null);
  const recommendation = lowestPrice && cheapest ? cheapest : best;

  return (
    <>
      <label className="guide-lowest">
        <input
          type="checkbox"
          checked={lowestPrice}
          onChange={(event) => setLowestPrice(event.currentTarget.checked)}
        />
        Lowest price
      </label>
      <table className="guide-shopping" aria-label="Sample bag counts and auction prices">
        <thead>
          <tr>
            <th scope="col">Elixir</th>
            <th scope="col">In bags</th>
            <th scope="col">Unit price</th>
          </tr>
        </thead>
        <tbody>
          {ranking.map(({ item }) => (
            <tr key={item} data-recommended={item === recommendation.item}>
              <th scope="row">
                <span className="guide-shop-item">
                  <img className="guide-icon" src={`${import.meta.env.BASE_URL}icons/${item}.jpg`} width="30" height="30" alt="" />
                  {elixirs[item].name}
                </span>
              </th>
              <td>{elixirs[item].count}</td>
              <td>
                <UnitPrice price={elixirs[item].price} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="guide-result" role="status">
        Suggested purchase <strong>{elixirs[recommendation.item].name}</strong>
      </p>
      <p className="guide-in-game">
        Run <strong>Full Scan</strong> in Auctionator to populate prices. A dash means the price is unknown.{' '}
        <strong>Lowest price</strong> changes the purchase suggestion and keeps your buff bar choice.
      </p>
    </>
  );
}

const wheelItems = [
  { kind: 'food', label: 'Food', name: 'Grilled Squid', icon: 'food', seconds: 900, count: 3 },
  { kind: 'elixir', label: 'Elixir', name: elixirs.mongoose.name, icon: 'mongoose', seconds: 1800, count: 2 },
  {
    kind: 'weapon',
    label: 'Main hand',
    name: 'Dense Sharpening Stone',
    icon: 'stone',
    seconds: 1800,
    count: 1,
  },
  {
    kind: 'attack',
    label: 'Attack power',
    name: 'Winterfall Firewater',
    icon: 'firewater',
    seconds: 1200,
    count: 2,
  },
] satisfies {
  kind: 'food' | 'elixir' | 'weapon' | 'attack';
  label: string;
  name: string;
  icon: string;
  seconds: number;
  count: number;
}[];

type WheelItem = (typeof wheelItems)[number];
type WheelSlot = { used: number; expiresAt: number };
type WheelState = {
  slots: Partial<Record<WheelItem['kind'], WheelSlot>>;
  lastUsed: { name: string; remaining: number } | null;
};

function formatTimer(milliseconds: number) {
  const seconds = Math.ceil(milliseconds / 1000);
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}

function WheelExample({ onClose }: { onClose: () => void }) {
  const [wheel, setWheel] = useState<WheelState>({ slots: {}, lastUsed: null });
  const [clock, setClock] = useState(0);
  const timerId = useId();
  const lastExpiry = Math.max(0, ...Object.values(wheel.slots).map((slot) => slot?.expiresAt ?? 0));

  useEffect(() => {
    if (lastExpiry <= Date.now()) return;
    const timer = window.setInterval(() => {
      const now = Date.now();
      setClock(now);
      if (now >= lastExpiry) window.clearInterval(timer);
    }, 1000);
    return () => window.clearInterval(timer);
  }, [lastExpiry]);

  function useItem(item: WheelItem) {
    const now = Date.now();
    setClock(now);
    setWheel((current) => {
      const used = (current.slots[item.kind]?.used ?? 0) + 1;
      if (used > item.count) return current;
      return {
        slots: { ...current.slots, [item.kind]: { used, expiresAt: now + item.seconds * 1000 } },
        lastUsed: { name: item.name, remaining: item.count - used },
      };
    });
  }

  return (
    <>
      <div className="guide-wheel" role="group" aria-label="Example buff wheel">
        {wheelItems.map((item) => {
          const slot = wheel.slots[item.kind];
          const remaining = item.count - (slot?.used ?? 0);
          const milliseconds = (slot?.expiresAt ?? 0) - clock;
          const isActive = slot !== undefined && milliseconds > 0;
          const sliceTimerId = `${timerId}-${item.kind}`;
          return (
            <button
              className="guide-slice"
              data-slot={item.kind}
              data-active={isActive}
              key={item.kind}
              type="button"
              aria-label={`${item.label}, ${item.name}, ${remaining} in bags${isActive ? ', buff active' : ''}`}
              aria-describedby={isActive ? sliceTimerId : undefined}
              aria-disabled={remaining === 0}
              title={item.name}
              onClick={() => {
                if (remaining > 0) useItem(item);
              }}
            >
              <span className="guide-slice-label">
                <img className="guide-icon" src={`${import.meta.env.BASE_URL}icons/${item.icon}.jpg`} width="34" height="34" alt="" />
                <strong>{item.label}</strong>
                <span>{remaining} in bags</span>
                {isActive && (
                  <span className="guide-timer" id={sliceTimerId} role="timer">
                    {formatTimer(milliseconds)} left
                  </span>
                )}
              </span>
            </button>
          );
        })}
        <button className="guide-wheel-hub" type="button" onClick={onClose}>
          Cancel
        </button>
      </div>
      <p className="guide-result guide-wheel-result" role="status">
        {wheel.lastUsed ? (
          <>
            <strong>{wheel.lastUsed.name}</strong> used · {wheel.lastUsed.remaining} in bags
          </>
        ) : (
          'No buffs active.'
        )}
      </p>
      <p className="guide-in-game">
        Outside combat, Shift-left-click the bar grip or type <code>/ab wheel</code>. The wheel fades in over a quarter of a second and accepts input immediately. Right-click the grip for settings. Set a shortcut in{' '}
        <strong>General</strong> to hold, aim at a slice, and release. Return to the center or press Escape to
        cancel.
      </p>
    </>
  );
}

type GuideDialogProps = { page: GuidePage | null; onClose: () => void };

export default function GuideDialog({ page, onClose }: GuideDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleRef = useRef<HTMLHeadingElement>(null);
  const startedOnBackdrop = useRef(false);
  const titleId = useId();
  const descriptionId = useId();
  const isOpen = page !== null;

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog || !isOpen) return;
    const trigger = document.activeElement;
    dialog.showModal();
    titleRef.current?.focus({ preventScroll: true });
    return () => {
      dialog.close();
      if (trigger instanceof HTMLElement && trigger.isConnected) {
        trigger.focus({ preventScroll: true });
      }
    };
  }, [isOpen]);

  return (
    <dialog
      className="guide-dialog"
      ref={dialogRef}
      aria-labelledby={titleId}
      aria-describedby={descriptionId}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      onPointerDown={(event) => {
        startedOnBackdrop.current = event.target === event.currentTarget;
      }}
      onClick={(event) => {
        if (startedOnBackdrop.current && event.target === event.currentTarget) onClose();
        startedOnBackdrop.current = false;
      }}
    >
      {page && (
        <div className="guide-window" key={page}>
          <header className="guide-header">
            <button className="guide-close" type="button" onClick={onClose} aria-label="Close example">
              <span aria-hidden="true" />
            </button>
            <h2 id={titleId} ref={titleRef} tabIndex={-1}>
              {pages[page].title}
            </h2>
            <p id={descriptionId}>
              <span className="guide-example-label">Interactive example</span>
              {' · '}
              {pages[page].description}
            </p>
          </header>
          <div className="guide-body">
            {page === 'rankings' && <RankingsExample />}
            {page === 'shopping' && <ShoppingExample />}
            {page === 'wheel' && <WheelExample onClose={onClose} />}
          </div>
        </div>
      )}
    </dialog>
  );
}
