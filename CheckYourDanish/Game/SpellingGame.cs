namespace CheckYourDanish.Game;

/// <summary>One entry in danish_nouns.json.</summary>
/// <param name="Gender">"en" (common) or "et" (neuter).</param>
public sealed record Noun(string Danish, string Gender, string[] English)
{
    /// <summary>The word as the capital letters to type.</summary>
    public string Letters => Danish.Trim().ToUpperInvariant();
}

public enum Stage { Spelling, Gender, Done }

public sealed class SpellingGame
{
    /// <summary>The keys of the on-screen keyboard, in Danish QWERTY order.</summary>
    public static readonly string[] KeyboardRows = ["QWERTYUIOPÅ", "ASDFGHJKLÆØ", "ZXCVBNM"];

    public static readonly string[] Genders = ["en", "et"];

    private static readonly HashSet<char> Keys = KeyboardRows.SelectMany(r => r).ToHashSet();

    private readonly Random _random = new();
    private readonly Queue<Noun> _deck = new();
    private IReadOnlyList<Noun> _words = [];

    public Noun? Current { get; private set; }

    public Stage Stage { get; private set; }

    /// <summary>How many characters of the current word are filled in.</summary>
    public int Filled { get; private set; }

    /// <summary>The position of the letter the ? button revealed, if any.</summary>
    public int? HintAt { get; private set; }

    /// <summary>Whether this word has had a wrong letter, a wrong gender or a hint.</summary>
    public bool Failed { get; private set; }

    public string? WrongGender { get; private set; }

    public int Correct { get; private set; }
    public int Wrong { get; private set; }
    public int Streak { get; private set; }
    public int BestStreak { get; private set; }

    public bool HasWords => _words.Count > 0;

    public char? NextLetter => Current is null || Stage != Stage.Spelling ? null : Current.Letters[Filled];

    public void SetWords(IEnumerable<Noun> words)
    {
        // Every letter must be on the keyboard; É is typed as E, and other characters such as
        // the hyphen in "t-shirt" are filled in automatically.
        _words = words
            .Where(w => w.Letters.Length > 1 && Genders.Contains(w.Gender) && w.English.Length > 0)
            .Where(w => w.Letters.Where(char.IsLetter).All(c => Keys.Contains(KeyFor(c))))
            .ToList();
        _deck.Clear();
    }

    public void SetScore(int correct, int wrong, int bestStreak)
    {
        Correct = correct;
        Wrong = wrong;
        BestStreak = bestStreak;
        Streak = 0;
    }

    public void ResetScore() => SetScore(0, 0, 0);

    /// <summary>Moves to the next word. Every word comes once before any repeats, in random order.</summary>
    public void NewRound()
    {
        if (_words.Count == 0) return;

        if (_deck.Count == 0)
        {
            var shuffled = _words.ToArray();
            _random.Shuffle(shuffled);
            if (shuffled.Length > 1 && shuffled[0] == Current)
                (shuffled[0], shuffled[^1]) = (shuffled[^1], shuffled[0]);
            foreach (var word in shuffled) _deck.Enqueue(word);
        }

        Current = _deck.Dequeue();
        Stage = Stage.Spelling;
        Filled = 1;
        HintAt = null;
        Failed = false;
        WrongGender = null;
        SkipNonLetters();
    }

    /// <summary>Fills in the next box if the letter is right; a wrong one fails the word.</summary>
    public bool TryLetter(char letter)
    {
        if (NextLetter is not { } next) return false;
        if (KeyFor(next) != char.ToUpperInvariant(letter))
        {
            MarkFailed();
            return false;
        }

        Filled++;
        HintAt = null;
        SkipNonLetters();
        return true;
    }

    /// <summary>Shows the next letter in its box, which then still has to be typed. Fails the word.</summary>
    public void Hint()
    {
        if (Stage != Stage.Spelling) return;
        HintAt = Filled;
        MarkFailed();
    }

    /// <summary>Answers the gender question. The word is finished once the right one is picked.</summary>
    public bool TryGender(string gender)
    {
        if (Stage != Stage.Gender || Current is null) return false;
        if (gender != Current.Gender)
        {
            WrongGender = gender;
            MarkFailed();
            return false;
        }

        WrongGender = null;
        Stage = Stage.Done;
        if (Failed)
        {
            Wrong++;
            Streak = 0;
        }
        else
        {
            Correct++;
            Streak++;
            BestStreak = Math.Max(BestStreak, Streak);
        }
        return true;
    }

    /// <summary>The keyboard key that types this character.</summary>
    public static char KeyFor(char c) => char.ToUpperInvariant(c) switch
    {
        'É' or 'È' => 'E',
        var upper => upper,
    };

    private void MarkFailed() => Failed = true;

    private void SkipNonLetters()
    {
        var letters = Current!.Letters;
        while (Filled < letters.Length && !char.IsLetter(letters[Filled])) Filled++;
        if (Filled == letters.Length) Stage = Stage.Gender;
    }
}
