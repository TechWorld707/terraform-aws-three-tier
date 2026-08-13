import json

import app as application


def test_health(tmp_path):
    app = application.create_app({"TESTING": True, "SQLALCHEMY_DATABASE_URI": f"sqlite:///{tmp_path}/test.db"})
    assert app.test_client().get("/health").status_code == 200


def test_valid_submission_is_saved_and_archived(monkeypatch, tmp_path):
    stored = {}

    class S3:
        def put_object(self, **kwargs):
            stored.update(kwargs)

    monkeypatch.setattr(application.boto3, "client", lambda *args, **kwargs: S3())
    app = application.create_app({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": f"sqlite:///{tmp_path}/test.db",
        "S3_BUCKET": "archive",
    })
    response = app.test_client().post("/api/submissions", json={"name": "Ada", "address": "1 Example Road", "age": 36})
    assert response.status_code == 201
    assert response.json["archive_status"] == "archived"
    assert json.loads(stored["Body"])["name"] == "Ada"


def test_invalid_submission_is_rejected(tmp_path):
    app = application.create_app({"TESTING": True, "SQLALCHEMY_DATABASE_URI": f"sqlite:///{tmp_path}/test.db"})
    response = app.test_client().post("/api/submissions", json={"name": "", "address": "x", "age": 999})
    assert response.status_code == 400
    assert len(response.json["errors"]) == 3
