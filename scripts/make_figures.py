"""Графики к README по результатам запросов из analysis/ (results/*.csv сохраняет CI)."""
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

R = "results/"
BLUE, ORANGE, GREY, PURPLE = "#2a6fdb", "#e07a1f", "#9aa5b1", "#7b4fc9"
plt.rcParams.update({"axes.spines.top": False, "axes.spines.right": False, "axes.grid": True, "grid.alpha": 0.3})

# 1. Заполняемость по моделям
lf = pd.read_csv(R + "bookings_load_factor.csv").sort_values("load_factor_pct")
fig, ax = plt.subplots(figsize=(9, 4.8))
colors = [ORANGE if x < 40 else BLUE for x in lf.load_factor_pct]
ax.barh(lf.model, lf.load_factor_pct, color=colors)
for y, (v, s, n) in enumerate(zip(lf.load_factor_pct, lf.seats, lf.flights)):
    ax.text(v + 0.8, y, f"{v:.0f}%  ·  {s} кресел, {n} рейсов", va="center", fontsize=9)
ax.set_xlim(0, 100)
ax.set_xlabel("заполняемость: посадочные талоны / кресла, %")
ax.set_title("Чаще всего летают малые борта, и они же самые пустые: Cessna заполнена на 14%, CRJ-200 на 37%", fontsize=11)
fig.tight_layout(); fig.savefig("images/load_factor.png", dpi=150); plt.close(fig)

# 2. Классы обслуживания
fm = pd.read_csv(R + "bookings_fare_mix.csv").set_index("fare_conditions").loc[["Economy", "Comfort", "Business"]]
fig, ax = plt.subplots(figsize=(8, 4.2))
x = np.arange(len(fm)); w = 0.27
for i, (col, lab, c) in enumerate([("seats_pct", "доля кресел", GREY), ("segments_pct", "доля проданных перелётов", BLUE), ("revenue_pct", "доля выручки", ORANGE)]):
    b = ax.bar(x + (i - 1) * w, fm[col], w, label=lab, color=c)
    ax.bar_label(b, fmt="%.0f%%", fontsize=8, padding=2)
ax.set_xticks(x, [f"{k}\nсредний тариф {v:,.0f} ₽".replace(",", " ") for k, v in fm.avg_fare.items()])
ax.set_ylabel("%"); ax.legend(frameon=False)
ax.set_title("Бизнес-класс: 11% кресел, 10% перелётов и 26,5% выручки", fontsize=11)
fig.tight_layout(); fig.savefig("images/fare_mix.png", dpi=150); plt.close(fig)

# 3. Глубина бронирования и цена
lt = pd.read_csv(R + "bookings_lead_time.csv")
lt = lt[lt.segments >= 500]
fig, ax1 = plt.subplots(figsize=(9, 4.4))
for cls, c in [("Economy", BLUE), ("Business", ORANGE)]:
    d = lt[lt.fare_conditions == cls]
    lab = [f"{a}–{b}" for a, b in zip(d.from_day, d.to_day)]
    ax1.plot(lab, d.avg_amount / 1000, marker="o", color=c, label=f"{cls}: средний тариф")
ax1.set_ylabel("средний тариф, тыс. ₽"); ax1.set_ylim(0, 60)
ax1.set_xlabel("дней между бронированием и вылетом")
eco = lt[lt.fare_conditions == "Economy"]
ax2 = ax1.twinx(); ax2.grid(False)
ax2.bar([f"{a}–{b}" for a, b in zip(eco.from_day, eco.to_day)], eco.segments / eco.segments.sum() * 100, color=GREY, alpha=0.35, label="Economy: доля перелётов")
ax2.set_ylabel("доля перелётов эконома, %"); ax2.spines["right"].set_visible(True)
ax1.set_zorder(ax2.get_zorder() + 1); ax1.patch.set_visible(False)
h1, l1 = ax1.get_legend_handles_labels(); h2, l2 = ax2.get_legend_handles_labels()
ax1.legend(h1 + h2, l1 + l2, frameon=False, loc="upper left", fontsize=9)
ax1.set_title("Цена почти не зависит от того, за сколько дней до вылета куплен билет", fontsize=11)
fig.tight_layout(); fig.savefig("images/lead_time.png", dpi=150); plt.close(fig)

# 4. Концентрация выручки
rp = pd.read_csv(R + "bookings_route_pareto.csv")
cp = pd.read_csv(R + "dvdrental_customer_pareto.csv")
fig, ax = plt.subplots(figsize=(6.4, 5))
for d, lab, c in [(rp, "маршруты авиакомпании", ORANGE), (cp, "покупатели DVD-проката (Pagila)", BLUE)]:
    share = d["rank"] / d.routes_total if "routes_total" in d else d["rank"] / d.customers_total
    ax.plot(np.r_[0, share * 100], np.r_[0, d.cum_revenue_pct], color=c, lw=2, label=lab)
ax.plot([0, 100], [0, 100], color=GREY, ls="--", lw=1, label="равномерно")
r20 = rp.loc[rp["rank"] <= round(0.2 * len(rp)), "cum_revenue_pct"].max()
c20 = cp.loc[cp["rank"] <= round(0.2 * len(cp)), "cum_revenue_pct"].max()
ax.axvline(20, color=GREY, lw=0.8)
ax.annotate(f"{r20:.0f}%", (20, r20), xytext=(26, r20 - 4), color=ORANGE, fontsize=10)
ax.annotate(f"{c20:.0f}%", (20, c20), xytext=(26, c20 - 6), color=BLUE, fontsize=10)
ax.set_xlabel("топ-N% маршрутов / покупателей по выручке"); ax.set_ylabel("накопленная доля выручки, %")
ax.legend(frameon=False, loc="lower right", fontsize=9)
ax.set_title("Топ-20% маршрутов приносят 71% выручки, а покупатели почти равны", fontsize=11)
fig.tight_layout(); fig.savefig("images/revenue_concentration.png", dpi=150); plt.close(fig)

n50 = (rp.cum_revenue_pct < 50).sum() + 1
print("routes:", len(rp), "top20% share:", r20, "routes for 50%:", n50, "customers top20% share:", c20)
print(lf[["model", "flights", "load_factor_pct"]])
