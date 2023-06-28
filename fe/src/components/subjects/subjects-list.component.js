import React, { Component } from "react";
import SubjectDataService from "../../services/subject.service";
import { Link } from "react-router-dom";

export default class SubjectsList extends Component {
  constructor(props) {
    super(props);
    this.onChangeSearchTitle = this.onChangeSearchTitle.bind(this);
    this.retrieveSubjects = this.retrieveSubjects.bind(this);
    this.refreshList = this.refreshList.bind(this);
    this.setActiveSubject = this.setActiveSubject.bind(this);
    this.removeAllSubjects = this.removeAllSubjects.bind(this);
    this.searchTitle = this.searchTitle.bind(this);

    this.state = {
      subjects: [],
      currentSubject: null,
      currentIndex: -1,
      searchTitle: ""
    };
  }

  componentDidMount() {
    this.retrieveSubjects();
  }

  onChangeSearchTitle(e) {
    const searchTitle = e.target.value;

    this.setState({
      searchTitle: searchTitle
    });
  }

  retrieveSubjects() {
    SubjectDataService.getAll()
      .then(response => {
        this.setState({
          subjects: response.data
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  refreshList() {
    this.retrieveSubjects();
    this.setState({
      currentSubject: null,
      currentIndex: -1
    });
  }

  setActiveSubject(subject, index) {
    this.setState({
      currentSubject: subject,
      currentIndex: index
    });
  }

  removeAllSubjects() {
    SubjectDataService.deleteAll()
      .then(response => {
        console.log(response.data);
        this.refreshList();
      })
      .catch(e => {
        console.log(e);
      });
  }

  searchTitle() {
    this.setState({
      currentSubject: null,
      currentIndex: -1
    });

    SubjectDataService.findByTitle(this.state.searchTitle)
      .then(response => {
        this.setState({
          subjects: response.data
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  render() {
    const { searchTitle, subjects, currentSubject, currentIndex } = this.state;

    return (
      <div className="list row">
        <div className="col-md-8">
          <div className="input-group mb-3">
            <input
              type="text"
              className="form-control"
              placeholder="Search by title"
              value={searchTitle}
              onChange={this.onChangeSearchTitle}
            />
            <div className="input-group-append">
              <button
                className="btn btn-outline-secondary"
                type="button"
                onClick={this.searchTitle}
              >
                Search
              </button>
            </div>
          </div>
        </div>
        <div className="col-md-6">
          <h4>Subjects List</h4>

          <ul className="list-group">
            {subjects &&
              subjects.map((subject, index) => (
                <li
                  className={
                    "list-group-item " +
                    (index === currentIndex ? "active" : "")
                  }
                  onClick={() => this.setActiveSubject(subject, index)}
                  key={index}
                >
                  {subject.title}
                </li>
              ))}
          </ul>

          <button
            className="m-3 btn btn-sm btn-danger"
            onClick={this.removeAllSubjects}
          >
            Remove All
          </button>
          <Link to={"/add_subject"} className="m-3 btn btn-sm btn-success">
            Add New
          </Link>
        </div>
        <div className="col-md-6">
          {currentSubject ? (
            <div>
              <h4>Subject</h4>
              <div>
                <label>
                  <strong>Title:</strong>
                </label>{" "}
                {currentSubject.title}
              </div>
              <div>
                <label>
                  <strong>Description:</strong>
                </label>{" "}
                {currentSubject.descr}
              </div>
              <div>
                <label>
                  <strong>Status:</strong>
                </label>{" "}
                {currentSubject.published ? "Published" : "Pending"}
              </div>

              <Link
                to={"/subjects/" + currentSubject._id.$oid}
                className="badge badge-warning"
              >
                Edit
              </Link>
            </div>
          ) : (
            <div>
              <br />
              <p>Please click on a Subject...</p>
            </div>
          )}
        </div>
      </div>
    );
  }
}
