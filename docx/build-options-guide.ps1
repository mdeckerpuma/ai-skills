$out = 'C:\Users\mdecker\.claude\skills\options-coach\outputs\Options-Study-Guide.docx'

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Add()
$sel  = $word.Selection

$doc.PageSetup.PageWidth    = $word.InchesToPoints(8.5)
$doc.PageSetup.PageHeight   = $word.InchesToPoints(11)
$doc.PageSetup.TopMargin    = $word.InchesToPoints(0.75)
$doc.PageSetup.BottomMargin = $word.InchesToPoints(0.75)
$doc.PageSetup.LeftMargin   = $word.InchesToPoints(0.75)
$doc.PageSetup.RightMargin  = $word.InchesToPoints(0.75)

$doc.Styles['Normal'].Font.Name = 'Arial'
$doc.Styles['Normal'].Font.Size = 10
$doc.Styles['Heading 1'].Font.Size = 13
$doc.Styles['Heading 1'].Font.Bold = 1
$doc.Styles['Heading 1'].Font.Name = 'Arial'
$doc.Styles['Heading 2'].Font.Size = 11
$doc.Styles['Heading 2'].Font.Bold = 1
$doc.Styles['Heading 2'].Font.Name = 'Arial'

function H1($t) { $sel.Style=$doc.Styles['Heading 1']; $sel.TypeText($t); $sel.TypeParagraph(); $sel.Style=$doc.Styles['Normal'] }
function H2($t) { $sel.Style=$doc.Styles['Heading 2']; $sel.TypeText($t); $sel.TypeParagraph(); $sel.Style=$doc.Styles['Normal'] }
function P($t)  { $sel.Style=$doc.Styles['Normal'];    $sel.TypeText($t); $sel.TypeParagraph() }
function B($t)  { $sel.Style=$doc.Styles['Normal']; $sel.Font.Bold=1; $sel.TypeText($t); $sel.Font.Bold=0; $sel.TypeParagraph() }
function Li($t) { $sel.Style=$doc.Styles['List Bullet']; $sel.TypeText($t); $sel.TypeParagraph(); $sel.Style=$doc.Styles['Normal'] }
function NL()   { $sel.Style=$doc.Styles['Normal']; $sel.TypeParagraph() }
function PB()   { $sel.InsertBreak(7) }

function Tbl($hdr, $rows) {
    $nC = $hdr.Count; $nR = $rows.Count + 1
    $tbl = $doc.Tables.Add($sel.Range, $nR, $nC)
    $tbl.Style = $doc.Styles['Table Grid']
    $tbl.PreferredWidthType = 2
    $tbl.PreferredWidth     = 100
    $tbl.Range.Font.Size    = 9
    $tbl.Range.Font.Name    = 'Arial'
    for ($c=0; $c -lt $nC; $c++) {
        $cell = $tbl.Cell(1,$c+1)
        $cell.Range.Text = $hdr[$c]
        $cell.Range.Font.Bold = 1
        $cell.Shading.BackgroundPatternColor = 10066329  # dark-ish gray
        $cell.Range.Font.Color = 16777215               # white text
    }
    for ($r=0; $r -lt $rows.Count; $r++) {
        for ($c=0; $c -lt $nC; $c++) {
            $cell = $tbl.Cell($r+2,$c+1)
            $cell.Range.Text = $rows[$r][$c]
            if ($r % 2 -eq 1) { $cell.Shading.BackgroundPatternColor = 15921906 } # light gray stripe
        }
    }
    $sel.Start = $tbl.Range.End
    $sel.End   = $tbl.Range.End
    $sel.TypeParagraph()
}

# ── TITLE PAGE ───────────────────────────────────────────────────────────────
$sel.ParagraphFormat.Alignment = 1
$sel.Font.Name='Arial'; $sel.Font.Size=30; $sel.Font.Bold=1
$sel.TypeText('OPTIONS TRADING'); $sel.TypeParagraph()
$sel.TypeText('STUDY GUIDE'); $sel.TypeParagraph()
$sel.Font.Size=12; $sel.Font.Bold=0
$sel.TypeText('Greeks  |  Volatility  |  Strategies  |  Rev Cons  |  Risk Management'); $sel.TypeParagraph()
NL
$sel.Font.Size=11
$sel.TypeText('TJY Options  --  Beginner Reference'); $sel.TypeParagraph()
$sel.ParagraphFormat.Alignment=0
PB

# ── TABLE OF CONTENTS ────────────────────────────────────────────────────────
H1 'Table of Contents'
$doc.TablesOfContents.Add($sel.Range,1,1,2) | Out-Null
$sel.TypeParagraph()
PB

# ============================================================================
#  1. OPTIONS BASICS
# ============================================================================
H1 '1. Options Basics'
P 'Every options concept traces back to one simple idea: an option gives one party a right, and the other party an obligation. The premium paid is the price of that right. Understanding who has the right and who has the obligation is the foundation of everything that follows.'

H2 'The Four Roles'
Tbl @('Role','Right or Obligation','You Profit When','Max Profit','Max Loss') @(
    @('Long Call',  'RIGHT to BUY 100 shares at the strike price',   'Stock rises above strike + premium paid',  'Unlimited (stock can rise forever)',  'Premium paid -- nothing more'),
    @('Short Call', 'OBLIGATION to SELL 100 shares at the strike',   'Stock stays at or below the strike',        'Premium received -- nothing more',    'Unlimited (stock can rise forever)'),
    @('Long Put',   'RIGHT to SELL 100 shares at the strike price',  'Stock falls below strike - premium paid',   'Strike minus premium (stock to zero)',  'Premium paid -- nothing more'),
    @('Short Put',  'OBLIGATION to BUY 100 shares at the strike',    'Stock stays at or above the strike',        'Premium received -- nothing more',    'Strike minus premium (stock to zero)')
)
P 'Notice the asymmetry: buyers have limited loss and unlimited (or large) upside. Sellers have limited gain and unlimited (or large) downside. This is why sellers collect premium upfront -- it compensates them for taking on the obligation.'

H2 'Intrinsic Value, Extrinsic Value, and Moneyness'
P 'Every option premium splits into two parts. Intrinsic value is the real, immediate value -- the amount an option is already in the money. Extrinsic value (also called time value) is everything else: the market''s estimate of what could still happen before expiration.'
NL
Tbl @('Term','Call Example (SPY at 522)','Put Example (SPY at 522)','Intrinsic?','Extrinsic?') @(
    @('ITM (In the Money)', '520 call -- stock is already above strike', '525 put -- stock is already below strike', 'YES: $2.00 (call) / $3.00 (put)', 'YES: remaining premium above intrinsic'),
    @('ATM (At the Money)', '522 call -- stock right at strike',          '522 put -- stock right at strike',          'None (zero intrinsic)',            'ALL of the premium is extrinsic'),
    @('OTM (Out of Money)', '525 call -- stock has not reached strike',   '520 put -- stock has not fallen to strike', 'None',                             'ALL of the premium is extrinsic')
)
NL
B 'Key Formulas:'
Li 'Call Intrinsic = max(0, Stock Price - Strike)   |   Put Intrinsic = max(0, Strike - Stock Price)'
Li 'Extrinsic (Time Value) = Total Premium - Intrinsic Value'
Li 'Breakeven (long call) = Strike + Premium Paid   |   Breakeven (long put) = Strike - Premium Paid'
Li '1 contract always controls exactly 100 shares. Always.'
NL
B 'Why This Matters for Everything Else:'
P 'Extrinsic value is what you are fighting as a buyer and earning as a seller. It is eaten by theta (time decay) every single day and shrinks when implied volatility falls. Deep ITM options have mostly intrinsic value -- they move almost dollar-for-dollar with the stock and have very little extrinsic left to decay. This is why deep ITM options have a delta near 1.00. ATM options have zero intrinsic -- they are made entirely of extrinsic -- which is why they decay the fastest and why premium sellers love selling ATM or near-ATM options.'

# ============================================================================
#  2. THE GREEKS
# ============================================================================
H1 '2. The Greeks'
P 'Greeks are the sensitivities of an option''s price to the factors that can change. Each Greek answers one question: if only this one thing changes, how much does my option gain or lose? In the real world, all of them are moving simultaneously -- which is why understanding how they interact is more important than memorizing any one Greek in isolation.'
NL

Tbl @('Greek','What It Measures','Long Option (buyer)','Short Option (seller)','Biggest When') @(
    @('Delta', 'Dollar change per $1 move in the stock',    '+0 to +1.00 (calls) / -1.00 to 0 (puts)', 'Opposite sign',                      'Deep ITM, directional trades'),
    @('Gamma', 'How fast delta changes per $1 stock move',  'Positive -- delta accelerates in your favor', 'Negative -- delta accelerates against you', 'ATM options near expiration'),
    @('Theta', 'Dollar lost (or gained) per calendar day',  'Negative -- you lose value every day',    'Positive -- you earn value every day',  'ATM, last 30 days before expiry'),
    @('Vega',  'Dollar change per 1% move in implied vol',  'Positive -- rising IV benefits you',       'Negative -- rising IV hurts you',        'Events: earnings, Fed, macro'),
    @('Rho',   'Dollar change per 1% move in rates',        'Calls positive, puts negative',            'Opposite',                               'LEAPS; ignore for short-dated')
)
NL

H2 'Delta -- Direction and Probability'
P 'Delta is the Greek most traders encounter first. It tells you two things at once: how much your option''s price moves per dollar move in the stock, and a rough estimate of the probability the option finishes in the money at expiration.'
Li 'ATM options have delta near 0.50. Deep ITM near 1.00. Deep OTM near 0.05.'
Li 'Delta approximates ITM probability: a 0.30 delta call has roughly a 30% chance of expiring ITM.'
Li 'Hedge ratio: long 1 call at 0.45 delta = equivalent directional exposure of long 45 shares of stock.'
Li 'The connection to intrinsic value: as an option goes deeper ITM and gains more intrinsic value, its delta rises toward 1.00 -- it behaves more and more like owning the stock itself.'

H2 'Gamma -- Why Delta Does Not Stay Still'
P 'Gamma is delta''s rate of change. It is the reason a short option position can go from manageable to dangerous very quickly. Long options have positive gamma -- each move in your favor makes your delta larger, so you earn more on the next move. Short options have negative gamma -- each move against you increases how much delta is working against you.'
NL
B 'Delta + Gamma in action:'
P 'You sell a straddle on SPY at 520. Your short call has delta -0.50 and gamma -0.08. SPY moves up $1 to 521. Your new call delta is approximately -0.50 - 0.08 = -0.58. SPY moves another $1 to 522 -- delta is now approximately -0.66. Each $1 move against you increases the pain by more than the last. This acceleration is gamma risk and is most dangerous for short options near expiration when gamma is at its peak.'
Li 'Gamma is highest ATM and near expiration -- this is when short positions are most vulnerable.'
Li 'Buying options (positive gamma) means every move works better for you than the last. This is why buyers love volatile days.'
Li 'Pin risk: near expiration, if the stock is exactly AT your short strike, gamma is near-infinite. A penny move flips the option from worthless to in-the-money. Always close short options before expiration.'

H2 'Theta -- Time Is Either Your Enemy or Your Friend'
P 'Theta is the daily dollar decay of an option''s extrinsic value. Remember: intrinsic value does not decay -- only extrinsic decays. An option sitting deep in the money with $20 intrinsic and $0.50 extrinsic will lose only the $0.50 extrinsic over time. An ATM option with $6 of pure extrinsic will bleed all $6 before expiration.'
Li 'Theta accelerates in the final 30 days. An ATM option at 30 DTE loses ~$10/day; same option at 7 DTE loses ~$28/day.'
Li 'Premium sellers collect theta as daily income. Buyers pay it. This trade-off is the core economics of options.'
Li 'Sweet spot for selling: 30-45 DTE. Enough time to be wrong and recover, but fast enough decay to matter.'

H2 'Vega -- Volatility Exposure and the Core Trade-Off'
P 'Vega measures how much your option gains or loses for each 1% change in implied volatility (IV). This is the tension at the heart of every options trade: theta and vega work in opposite directions. As a buyer, you collect positive vega (you want IV to rise) but you pay negative theta (time works against you). As a seller, you collect positive theta (earn every day) but hold negative vega (an IV spike hurts you).'
NL
B 'Why options get expensive before events:'
P 'Before earnings, the market does not know if the stock will move 2% or 12%. That uncertainty is priced into options as elevated IV. Traders buying puts for protection, and speculators buying calls and straddles, all bid up option prices. When the event resolves -- good or bad -- the uncertainty is gone, so IV collapses back to normal. This is vol crush.'
NL
B 'The vol crush trap (exam-critical):'
P 'AAPL is at $195. Earnings in 2 days. IV = 72%, normal IV is 24%, IVR = 94. You buy the 195 straddle for $12.00. Your breakevens are $183 and $207. Earnings hit: AAPL moves to $202 -- a $7 move. You think you won. But IV crashed from 72% to 22%. Your straddle is now worth only $6.20. You lost $5.80 on the trade even though the stock moved in a direction. Why? The $12 premium assumed a large move was possible AND priced in the vol uncertainty. Once the event passed, both were gone. The stock moved less than the market feared, and the uncertainty premium evaporated. This is why IVR matters before every trade involving buying premium.'

# ============================================================================
#  3. VOLATILITY
# ============================================================================
H1 '3. Volatility'
P 'Volatility is the single most important pricing input after the stock price itself. Two traders can look at the same option and have completely different views of its value depending on whether they think future volatility will be higher or lower than what is currently priced in.'

H2 'Implied vs Historical Volatility'
Li 'Implied Volatility (IV): what the market is EXPECTING future price movement to be, expressed as an annualized standard deviation percentage. Back-solved from current option prices.'
Li 'Historical Volatility (HV): what the stock ACTUALLY moved in the past 20-30 days. Backward-looking fact, not a forecast.'
Li 'The edge: if IV is 30% but the stock has been moving at a 15% HV pace, options are overpriced for what the stock is actually doing. The market fears more movement than is happening -- sell premium.'
Li 'If IV is 15% but the stock has been moving at 30% HV, options are cheap relative to actual moves -- buy premium.'
Li 'Daily Expected Move (1 standard deviation): Stock Price x IV% / 16    Example: SPY 520 x 16% / 16 = $5.20/day (68% of days within +/- $5.20)'

H2 'IV Rank (IVR) -- Where IV Stands Relative to Its Own History'
P 'IVR answers the question: is IV high or low RIGHT NOW compared to how high it has been over the past year? A stock with IV at 40% may be cheap (if it spent most of the year at 70%) or expensive (if it normally sits at 15%).'
NL
P 'Formula:   IVR = (Current IV - 52-Week Low IV) / (52-Week High IV - 52-Week Low IV) x 100'
NL
Tbl @('IVR','What It Means','Best Strategy','Why') @(
    @('0 - 30',   'IV is low relative to its history -- options are cheap',     'Buy premium: debit spreads, long calls/puts, straddles', 'Low cost to buy. If IV rises, vega works for you.'),
    @('30 - 60',  'IV is average -- no structural edge from volatility alone',   'Follow direction. Condors OK with caution.',             'No strong vol signal. Trade the trend.'),
    @('60 - 100', 'IV is elevated relative to its history -- options expensive', 'Sell premium: credit spreads, condors, straddles',       'High-priced options likely to revert lower. Theta + falling IV = double benefit for sellers.')
)
NL
B 'IVR + Vega together (exam question):'
P 'You sell a bull put spread when IVR = 80. You are short premium, which means short vega (negative vega). If IV falls from 80 IVR back toward 40 IVR over the next two weeks, your spread benefits from BOTH theta decay AND the vega gain from falling IV. This double-benefit is why premium sellers target high IVR setups. Conversely, if you buy a straddle when IVR = 80 and IV mean-reverts lower, you lose on vega even if the stock stays near your strike.'

# ============================================================================
#  4. PUT-CALL PARITY, REV CONS, SYNTHETICS
# ============================================================================
H1 '4. Put-Call Parity, Reversals and Synthetics'
P 'Put-call parity is the law of options pricing. It is not a theory -- it is a constraint that must hold or risk-free money is available. Every synthetic position and every reversal/conversion trade flows directly from this one equation.'

H2 'Put-Call Parity'
P 'For European options (exercisable only at expiration, like SPX):'
NL
P 'C - P = S - K/(1+r)^T     where C = call price, P = put price, S = stock price, K = strike, r = risk-free rate, T = time in years'
NL
P 'Plain English: the difference in price between a call and a put at the same strike must equal the stock price minus the present value of the strike. If this relationship is violated, you can lock in risk-free profit.'
NL
B 'Example:'
Li 'XYZ at $100. Strike = 100. Rate = 5%. T = 1 year. PV(K) = 100/1.05 = $95.24.'
Li 'Theoretical: C - P should = 100 - 95.24 = $4.76. So if Call = $10.00, Put must = $5.24.'
Li 'If the Put trades at $3.00 instead of $5.24, the put is $2.24 underpriced -- arbitrage exists.'

H2 'Reversals and Conversions (Rev Cons)'
P 'Rev cons are the three-legged trades that exploit put-call parity violations. They lock in the mispricing between calls and puts relative to the stock price.'
NL
Tbl @('Trade','Stock Leg','Call Leg','Put Leg','Exploits','Classic Risk') @(
    @('Reversal',   'Long 100 shares',  'Short ATM call', 'Long ATM put',  'Overpriced calls / underpriced puts', 'Early call assignment around ex-dividend'),
    @('Conversion', 'Short 100 shares', 'Long ATM call',  'Short ATM put', 'Overpriced puts / underpriced calls', 'Hard-to-borrow cost eats the arb profit')
)
NL
B 'Rev Con Limits -- Why the Arb Disappears:'
Li 'Hard-to-borrow: shorting the stock costs a borrow fee that reduces or eliminates profit on conversions.'
Li 'Dividends: holders of long calls exercise early to capture a dividend, creating assignment risk on the reversal leg.'
Li 'Bid-ask spreads: executing 3 legs in a real market means crossing the spread 3 times. The arb must be larger than those combined costs.'
Li 'Pin risk at expiration: if the stock closes exactly at the strike, you do not know which legs get exercised.'

H2 'Synthetics -- Same Risk, Different Structure'
P 'Because of put-call parity, any position can be replicated another way. Knowing this lets you pick the most capital-efficient structure for your view.'
NL
Tbl @('Synthetic','How to Build It','Equivalent To','Practical Use') @(
    @('Synthetic Long Stock',  'Long ATM call + Short ATM put (same strike/expiry)', 'Long 100 shares',   'Same delta exposure, far less capital tied up'),
    @('Synthetic Short Stock', 'Short ATM call + Long ATM put (same strike/expiry)', 'Short 100 shares',  'Short exposure without needing to locate a borrow'),
    @('Covered Call = Short Put', 'Long 100 shares + Short OTM call', 'Short OTM put alone','Both: limited gain, same breakeven, same max loss. Pick whichever uses less capital.')
)
NL
B 'Covered Call equals Short Put -- the proof:'
P 'You own 100 shares of SPY at 520 and sell the 530 call for $3.00. Max gain = $10 + $3 = $13 per share. Max loss = stock falls to zero, partially offset by $3 premium. Breakeven = 517. Now compare to just selling the 530 put for $3.00 with cash to cover. Max gain = $3 premium. Breakeven = 527. Wait -- these are NOT the same if the strikes differ. The equivalence is: covered call at strike K = short put at strike K. Same strike, same expiration. Try it: own SPY at 520, sell 520 call for $6. That has the same P&L as selling the 520 put for $6 (adjusted for carrying cost). This is put-call parity in action.'

# ============================================================================
#  5. STRATEGIES
# ============================================================================
H1 '5. Strategies Reference'
P 'Choosing a strategy is not random -- it follows from your market outlook, your volatility view (IVR), and your risk tolerance. The map below shows all major structures. When in doubt: check IVR first, then your directional view, then choose defined vs undefined risk.'
NL

Tbl @('Strategy','Construction','Outlook','Max Profit','Max Loss','IVR','Theta','Vega') @(
    @('Long Call',       'Buy OTM or ATM call',                          'Bullish',          'Unlimited',       'Premium paid',    'Low (< 30)',   'Negative','Positive'),
    @('Long Put',        'Buy OTM or ATM put',                           'Bearish',          'Strike-prem',     'Premium paid',    'Low (< 30)',   'Negative','Positive'),
    @('Bull Put Spread', 'Short higher put + Long lower put (credit)',    'Bullish/neutral',  'Net credit',      'Width - credit',  'High (60+)',   'Positive','Negative'),
    @('Bear Call Spread','Short lower call + Long higher call (credit)',  'Bearish/neutral',  'Net credit',      'Width - credit',  'High (60+)',   'Positive','Negative'),
    @('Short Straddle',  'Short ATM call + Short ATM put (same strike)',  'Neutral, pinning', 'Total credit',    'Unlimited',       'High (70+)',   'Positive','Negative'),
    @('Short Strangle',  'Short OTM call + Short OTM put',               'Neutral, range',   'Total credit',    'Unlimited',       'High (65+)',   'Positive','Negative'),
    @('Iron Condor',     'Bear call spread + Bull put spread',            'Neutral range',    'Net credit',      'Width - credit',  'High (60+)',   'Positive','Negative'),
    @('Iron Butterfly',  'Short ATM call + Short ATM put + OTM wings',   'Neutral, pin ATM', 'Net credit',      'Width - credit',  'High (70+)',   'Positive','Negative'),
    @('Covered Call',    'Long 100 shares + Short OTM call',             'Neutral-bullish',  'Credit + run-up', 'Stock - credit',  'Any',         'Positive','Negative'),
    @('Calendar Spread', 'Long back-month + Short front-month (same K)', 'Neutral near-term','IV differential', 'Debit paid',      'Rising IV',   'Net pos', 'Positive')
)
NL
P 'Notice the pattern: every strategy with positive theta also has negative vega. Every strategy with positive vega has negative theta. This is not a coincidence -- it is the fundamental trade-off of options. You cannot have a position that earns from both time passing AND volatility rising at the same time.'

H2 'Iron Condor -- Full Walkthrough'
P 'The iron condor is the most popular defined-risk neutral strategy. It is simply a short strangle with defined-risk wings bolted on. Understanding the condor means understanding the short strangle, the credit spread, and how they combine.'
Li 'Setup: SPY at 520, 30 DTE, IVR = 75, HV = 16% (options are expensive relative to actual moves)'
Li 'Sell 530 call / Buy 535 call (bear call spread) = $1.30 credit'
Li 'Sell 510 put / Buy 505 put (bull put spread) = $1.30 credit'
Li 'Total credit = $2.60. Max profit = $260 (SPY stays between 510 and 530). Max loss = $240 (breaks 505 or 535).'
Li 'The condor earns from BOTH theta decay each day AND from IV mean-reverting lower (high IVR to average).'
Li 'Manage at 50% profit ($130 gain). Exit if loss reaches $480 (2x credit). Roll untested side in only for a credit.'

H2 'Straddle vs Strangle vs Condor -- How They Relate'
Tbl @('','Short Straddle','Short Strangle','Iron Condor') @(
    @('Short Strikes',   'Both ATM (same strike)',       'OTM call + OTM put',        'OTM call + OTM put (same as strangle)'),
    @('Long Strikes',    'None (undefined risk)',        'None (undefined risk)',      'Further OTM call and put (wings)'),
    @('Risk',            'Unlimited both sides',         'Unlimited both sides',       'Defined -- max loss = width minus credit'),
    @('Max Premium',     'Highest (ATM = most extrinsic)','Less than straddle',        'Less than strangle (wing purchase costs money)'),
    @('Profit Zone',     'Narrowest',                    'Wider than straddle',        'Wider still, same as strangle strikes'),
    @('Capital Required','High (undefined risk margin)', 'High (undefined risk margin)','Low (defined risk = small margin)')
)

# ============================================================================
#  6. RISK MANAGEMENT
# ============================================================================
H1 '6. Risk Management'
P 'No strategy survives without risk management. The Greeks tell you what can hurt you. Risk management rules tell you how much of that hurt you will accept before acting.'

H2 'The Non-Negotiable Rules'
Li 'Never risk more than 2% of account on one trade. ($50k account = $1,000 max loss per trade.)'
Li 'Use defined-risk trades (spreads, condors) until you have at least 50 real trades completed.'
Li 'Close winners at 50% of max profit. The remaining potential gain is not worth the remaining risk.'
Li 'If a position loses 2x the original credit received, close it immediately. No debate, no rolling losers.'
Li 'Roll only for a net credit. Rolling for a debit = paying money to extend a losing trade.'
Li 'Check the ex-dividend date before holding any short calls overnight. Deep ITM calls will be assigned.'
Li 'Correlated positions multiply your exposure. Five condors on tech stocks = one giant tech bet, not five independent trades.'

H2 'Position Sizing -- Account by Account'
Tbl @('Account Size','2% Max Loss Per Trade','Iron Condor Contracts (approx $240 risk each)') @(
    @('$10,000','$200',  '0-1 contracts -- build the habit before scaling'),
    @('$25,000','$500',  '2 contracts per trade'),
    @('$50,000','$1,000','4 contracts per trade'),
    @('$100,000','$2,000','8 contracts per trade')
)
NL
H2 'Rolling -- When It Makes Sense'
P 'Rolling means closing your current position and reopening it at a different strike or expiration to extend the trade. The strict rule: ONLY roll for a net credit. If you cannot collect any credit by rolling, the position has no remaining edge and should be closed at a loss.'
Li 'Roll in time (same strike, later expiration): when the position is OTM with < 14 DTE left. Collect fresh premium.'
Li 'Roll down/up AND out (new strike, later expiration): when one side is tested. Move the tested spread further OTM and collect a credit on the roll.'
Li 'Never roll to avoid a loss. Rolling for a debit because you ''just need more time'' is how small losses become large ones.'

# ============================================================================
#  7. TRADE SCENARIOS
# ============================================================================
H1 '7. Trade Scenarios'
P 'These scenarios test how the concepts from all six chapters interact. Read each setup, answer the questions yourself, then check the analysis. This is the format of the options-coach drills.'

H2 'Scenario 1 -- Vol Crush: When Being Right is Not Enough'
Tbl @('','Detail') @(
    @('Setup',          'AAPL at $195. Earnings in 2 days. IV = 72%, HV = 24%, IVR = 94.'),
    @('Trade',          'Buy the 195 straddle (ATM call + ATM put, 2 DTE) for $12.00 ($1,200 total).'),
    @('Your Breakevens','Lower = 195 - 12 = $183.00   |   Upper = 195 + 12 = $207.00'),
    @('What Happened',  'Earnings hit. AAPL moves from $195 to $202 -- a $7 move. IV drops from 72% to 22%.'),
    @('Result',         'Your straddle is now worth approximately $6.20. You LOST $5.80 despite being directionally correct.'),
    @('Why',            'The $12 premium priced in a large move PLUS the uncertainty. Once earnings resolved, that uncertainty premium (vega) evaporated. AAPL moved $7 but the market had priced in the potential for a $12+ move. The vol crush destroyed more value than the directional move created.'),
    @('The Flip',       'The SHORT straddle seller collected $12 and bought it back at $6.20 -- profit of $5.80. Same trade, opposite side. High IVR = sell premium before events, not buy.')
)
NL
B 'Topics tested: Vega, vol crush, IVR, straddle breakeven, theta vs vega trade-off, why high IVR favors sellers.'

H2 'Scenario 2 -- Iron Condor Under Pressure'
Tbl @('','Detail') @(
    @('Setup',       'SPY at 520. Sell 530/535 call spread + 510/505 put spread for $3.00 credit. Max loss = $200.'),
    @('Week 1',      'SPY falls to 512. Put spread (510/505) is now worth $2.80. You are down $1.20 on the put side.'),
    @('2x Rule Check','2x your original credit = $6.00. You are at $1.20 loss -- well within range. No panic required.'),
    @('Good Response','Roll the 510/505 put spread down to 505/500 for a credit (if the market allows). This moves your tested side further away from the stock price.'),
    @('Bad Response', 'Hold and hope. Add more condors to ''average in.'' Roll for a debit. All three of these extend a losing position without edge.'),
    @('If SPY hits 507','Put spread is now worth ~$4.20. Loss = $1.20. Approaching 2x ($6.00 loss). Evaluate closing the whole condor NOW before the short 505 put goes deep ITM.'),
    @('Key Lesson',  'The condor profits from TIME (theta) and FALLING IV (vega). A directional move against you works against BOTH. When the stock moves, your positive theta stops mattering -- gamma and delta take over.')
)
NL
B 'Topics tested: Condor structure, theta/vega interplay, rolling rules, 2x loss rule, gamma risk as expiry nears.'

H2 'Scenario 3 -- Reversal Arbitrage (Rev Con in Practice)'
Tbl @('','Detail') @(
    @('Setup',       'Stock XYZ at $100. 100 Call (30 DTE) = $4.50. 100 Put (30 DTE) = $2.00. Risk-free rate = 5%, T = 30/365.'),
    @('Parity Check','PV(K) = 100 / (1 + 0.05)^(30/365) = $99.60. Theoretical put price = 4.50 - 100 + 99.60 = $4.10.'),
    @('The Violation','The put trades at $2.00 but should be $4.10. The put is underpriced by $2.10, meaning the call is overpriced relative to the put.'),
    @('The Trade',   'REVERSAL: Buy 100 shares + Buy the 100 Put at $2.00 + Sell the 100 Call at $4.50. Net option credit = $2.50.'),
    @('Carry Cost',  'Financing $100 stock for 30 days at 5% costs ~$0.41. Net arb after carry = $2.50 - $0.41 = $2.09 profit.'),
    @('What Can Kill It','Hard-to-borrow stock (short-sale fee on similar trades). Ex-dividend risk causing early call assignment. Wide bid-ask spreads eating the $2.09. Market makers often eliminate these mispricings within seconds.'),
    @('Key Lesson',  'Rev cons do not rely on direction, volatility, or time -- they are pure math. But the limits to arbitrage (borrow cost, dividends, transaction costs) are real. In modern markets, these opportunities are rare and fleeting.')
)
NL
B 'Topics tested: Put-call parity formula, reversal construction, carry cost, limits to arbitrage, synthetics.'

H2 'Scenario 4 -- Greeks Working Together: The Short Straddle'
Tbl @('','Detail') @(
    @('Setup',      'You sell a short straddle on SPY at 520 for $11.80 ($1,180 credit). 30 DTE. Delta = 0, Theta = +$12/day, Vega = -$80 per 1% IV move.'),
    @('Day 1-10',   'SPY stays between 515-525. Theta earns you ~$120 over 10 days. IV stays flat. P&L: +$120.'),
    @('Day 11',     'Market selloff. SPY drops to 510. IV spikes from 20% to 28% (8% jump). Vega loss = 8 x $80 = -$640. Delta loss on the put side = ~-$150. Total P&L after day 11: +$120 - $640 - $150 = -$670.'),
    @('Lesson 1',   'Theta earned $12/day for 10 days = $120. One vega spike wiped out 56 days worth of theta in a single day. This is why you must check IVR before selling straddles -- high IVR provides a bigger cushion for vega spikes.'),
    @('Day 15',     'SPY recovers to 518. IV falls back to 21%. Vega gain = 7 x $80 = +$560. Theta gain = 4 more days = +$48. P&L from peak loss: -$670 + $560 + $48 = -$62. Approaching breakeven.'),
    @('Key Lesson', 'Short straddles fight with theta and lose with vega. Managing straddles means watching IV, not just price. A stock that moves then recovers can still be a winning trade if IV normalizes.')
)
NL
B 'Topics tested: Theta vs vega conflict, delta/gamma on directional moves, IVR timing, how all Greeks interact on one trade.'

# ============================================================================
#  QUICK REFERENCE
# ============================================================================
H1 'Quick Reference'

H2 'All Key Formulas'
Tbl @('Formula','Expression','When You Use It') @(
    @('Put-Call Parity',         'C - P = S - K/(1+r)^T',                            'Checking for rev con opportunity; understanding synthetics'),
    @('Call Intrinsic',          'max(0, Stock Price - Strike)',                       'Splitting premium into real vs time value'),
    @('Put Intrinsic',           'max(0, Strike - Stock Price)',                       'Same'),
    @('Extrinsic Value',         'Premium - Intrinsic Value',                         'What is at risk from theta and vega decay'),
    @('IV Rank',                 '(Current IV - 52wk Low) / (52wk High - 52wk Low) x 100','Before every trade to determine buy vs sell premium'),
    @('Daily Move (1 SD)',       'Stock Price x IV% / 16',                            'Setting expectations for daily range; sizing straddle strikes'),
    @('Weekly Move (1 SD)',      'Stock Price x IV% / sqrt(52)',                      'Setting condor wing distances'),
    @('Credit Spread Max Profit','Net premium received',                              'Entry'),
    @('Credit Spread Max Loss',  'Strike width - net premium received',               'Position sizing'),
    @('Breakeven (credit spread)','Short strike +/- net credit',                      'Where you stop making money'),
    @('Long Call Breakeven',     'Strike + Premium Paid',                             'Entry on directional trades'),
    @('Long Put Breakeven',      'Strike - Premium Paid',                             'Entry on bearish directional trades'),
    @('Return on Capital',       'Max Profit / Capital at Risk x 100',               'Comparing strategies and strike selections')
)
NL

H2 'Strategy Selection Flow'
Tbl @('Step','Question','Answer --> Action') @(
    @('1','What is the IVR?',                   'IVR > 60: sell premium.  IVR < 30: buy premium.  30-60: follow trend.'),
    @('2','What is your directional view?',      'Bullish: bull put spread or long call.  Bearish: bear call spread or long put.  Neutral: condor, straddle, strangle.'),
    @('3','Defined or undefined risk?',          'Beginner / small account: defined risk only (spreads, condors).  Experienced: can use straddles/strangles with strict rules.'),
    @('4','How far OTM should the short strike be?','30 DTE condors: short strike at 1 SD away (use stock x IV% / sqrt(52) for weekly SD).  Aim for ~30 delta on the short strikes.'),
    @('5','When do I exit?',                     'At 50% profit OR at 2x max credit as a loss. No exceptions.')
)
NL

H2 'At-a-Glance: What To Do When...'
Tbl @('Situation','Action') @(
    @('IVR > 60',                    'Sell premium. Condors, credit spreads, straddles.'),
    @('IVR < 30',                    'Buy premium. Debit spreads, long options.'),
    @('Earnings announcement coming','High IVR: sell straddle/strangle. Low IVR: buy straddle. Check breakevens vs expected move.'),
    @('IV spikes suddenly',          'Short options losing on vega. Review size. Consider closing vega exposure.'),
    @('Position at 50% profit',      'Close it. Lock in the gain. The last 50% of potential profit carries 100% of remaining risk.'),
    @('Position at 2x loss',         'Close immediately. No rolling, no averaging down, no debate.'),
    @('Near ex-dividend date',       'Close any short ITM calls. They will be assigned the day before ex-div.'),
    @('Less than 7 DTE on short',    'Close short options. Gamma spikes near expiration. Do not hold short options into expiry.'),
    @('Stock pins your short strike','You face pin risk. Close before expiration. Assignment is random and unknowable at the pin.')
)

NL
$sel.ParagraphFormat.Alignment=1
$sel.Font.Size=9; $sel.Font.Italic=1
$sel.TypeText('Options trading involves substantial risk of loss. This guide is for educational purposes only and is not financial advice.')
$sel.Font.Italic=0; $sel.ParagraphFormat.Alignment=0

$doc.TablesOfContents.Item(1).Update()
$doc.SaveAs([ref]$out, [ref]16)
$pages = $doc.ComputeStatistics(2)
Write-Host "Done.  Pages: $pages  |  Saved: $out"
$doc.Close($false)
$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
