import re
import string

# ML packages are optional - app works without them using fallback methods
try:
    from sklearn.feature_extraction.text import TfidfVectorizer, ENGLISH_STOP_WORDS
    from sklearn.metrics.pairwise import cosine_similarity
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    ENGLISH_STOP_WORDS = set()

# SentenceTransformer is lazy-loaded to prevent slow startup and build/migration crashes.
_ai_model = None
AI_AVAILABLE = None  # None: not checked, True: loaded successfully, False: unavailable/failed

def get_ai_model():
    global _ai_model, AI_AVAILABLE
    if AI_AVAILABLE is False:
        return None
    if _ai_model is not None:
        return _ai_model
    try:
        from sentence_transformers import SentenceTransformer
        print("Loading SentenceTransformer model 'all-MiniLM-L6-v2'...")
        _ai_model = SentenceTransformer("all-MiniLM-L6-v2")
        AI_AVAILABLE = True
        print("SentenceTransformer loaded successfully.")
        return _ai_model
    except Exception as e:
        print(f"Failed to load SentenceTransformer: {e}")
        AI_AVAILABLE = False
        _ai_model = None
        return None



# ------------------ PREPROCESSING ------------------

def clean_text(text):
    text = text.lower()
    text = text.translate(str.maketrans('', '', string.punctuation))
    words = text.split()
    words = [w for w in words if w not in ENGLISH_STOP_WORDS]
    return " ".join(words)


def split_sentences(text):
    text = text.strip()
    if not text:
        return []
    sentences = re.split(r'(?<=[.!?])\s+', text)
    return [s.strip() for s in sentences if s.strip()]


# ------------------ SIMILARITY METHODS ------------------

def tfidf_similarity(s1, s2):
    if not SKLEARN_AVAILABLE:
        return 0.0
    if not s1.strip() or not s2.strip():
        return 0.0
    try:
        tfidf = TfidfVectorizer()
        vectors = tfidf.fit_transform([s1, s2])
        return cosine_similarity(vectors[0], vectors[1])[0][0]
    except Exception:
        return 0.0


def ngram_similarity(s1, s2, n=3):
    def get_ngrams(text):
        words = text.split()
        return set(zip(*[words[i:] for i in range(n)]))

    n1 = get_ngrams(s1)
    n2 = get_ngrams(s2)

    if not n1 or not n2:
        return 0

    return len(n1 & n2) / len(n1 | n2)


def ai_similarity(s1, s2):
    model = get_ai_model()
    if model is None:
        return 0.0
    if not s1.strip() or not s2.strip():
        return 0.0
    try:
        from sentence_transformers import util as st_util
        e1 = model.encode(s1, convert_to_tensor=True)
        e2 = model.encode(s2, convert_to_tensor=True)
        return st_util.cos_sim(e1, e2).item()
    except Exception as e:
        print(f"Error during AI similarity calculation: {e}")
        return 0.0



# ------------------ MAIN FUNCTION ------------------

def compare_docs(doc1, doc2):
    if not doc1.strip() or not doc2.strip():
        return 0.0

    doc1 = clean_text(doc1)
    doc2 = clean_text(doc2)

    if not doc1 or not doc2:
        return 0.0

    sents1 = split_sentences(doc1)
    sents2 = split_sentences(doc2)

    if not sents1 or not sents2:
        return 0.0

    total_score = 0
    count = 0

    for s1 in sents1:
        best_score = 0

        for s2 in sents2:
            try:
                tf = tfidf_similarity(s1, s2)
                ng = ngram_similarity(s1, s2)
                ai = ai_similarity(s1, s2)

                # Adjust weights based on available methods
                if SKLEARN_AVAILABLE and AI_AVAILABLE:
                    score = (0.55 * tf) + (0.25 * ng) + (0.20 * ai)
                elif SKLEARN_AVAILABLE:
                    score = (0.70 * tf) + (0.30 * ng)
                else:
                    score = float(ng)  # ngram only, no dependencies needed

                best_score = max(best_score, score)
            except Exception:
                continue

        if best_score > 0:
            total_score += best_score
            count += 1

    if count == 0:
        return 0

    return total_score / count


# ------------------ OPTIONAL: DEBUG FUNCTION ------------------

def compare_with_details(doc1, doc2):
    doc1 = clean_text(doc1)
    doc2 = clean_text(doc2)

    sents1 = split_sentences(doc1)
    sents2 = split_sentences(doc2)

    results = []

    for s1 in sents1:
        for s2 in sents2:
            tf = tfidf_similarity(s1, s2)
            ng = ngram_similarity(s1, s2)
            ai = ai_similarity(s1, s2)

            if SKLEARN_AVAILABLE and AI_AVAILABLE:
                score = (0.55 * tf) + (0.25 * ng) + (0.20 * ai)
            elif SKLEARN_AVAILABLE:
                score = (0.70 * tf) + (0.30 * ng)
            else:
                score = float(ng)

            if score > 0.7:
                results.append({
                    "sentence_1": s1,
                    "sentence_2": s2,
                    "score": round(score, 2)
                })

    return results
